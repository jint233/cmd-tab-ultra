import ApplicationServices
import Cocoa

enum WindowState {
    case unavailable
    case noStandardWindows
    case allStandardWindowsMinimized
    case hasVisibleStandardWindow
}

func windowState(for app: NSRunningApplication) -> WindowState {
    let axApp = appAccessibilityElement(for: app)

    var windowsRef: CFTypeRef?
    guard
        AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
            == .success,
        let windows = windowsRef as? [AXUIElement]
    else {
        debugLogAgent(
            "windowState unavailable app=\(app.localizedName ?? "unknown") bundle=\(app.bundleIdentifier ?? "nil") pid=\(app.processIdentifier)"
        )
        return .unavailable
    }

    var standardWindowCount = 0
    var minimizedCount = 0
    for window in windows {
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &roleRef)
        guard (roleRef as? String) == kAXWindowRole as String else { continue }
        standardWindowCount += 1

        if axBoolAttribute(kAXMinimizedAttribute as CFString, of: window) {
            minimizedCount += 1
        }
    }

    debugLogAgent(
        "windowState app=\(app.localizedName ?? "unknown") bundle=\(app.bundleIdentifier ?? "nil") pid=\(app.processIdentifier) windows=\(windows.count) standard=\(standardWindowCount) minimized=\(minimizedCount)"
    )

    if standardWindowCount == 0 {
        return .noStandardWindows
    }
    if minimizedCount == standardWindowCount {
        return .allStandardWindowsMinimized
    }
    return .hasVisibleStandardWindow
}
