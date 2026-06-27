import ApplicationServices
import Cocoa

func ensureVisibleWindow(app: NSRunningApplication) {
    debugLogAgent(
        "ensure app=\(app.localizedName ?? "unknown") bundle=\(app.bundleIdentifier ?? "nil") pid=\(app.processIdentifier) policy=\(app.activationPolicy.rawValue)"
    )
    guard !skippedBundleIDs.contains(app.bundleIdentifier ?? "") else { return }
    guard app.activationPolicy == .regular else { return }

    switch windowState(for: app) {
    case .unavailable, .noStandardWindows:
        debugLogAgent(
            "reopen app=\(app.localizedName ?? "unknown") reason=no-window-or-unavailable")
        reopenApplication(for: app, verifyAfterReopen: true)
    case .allStandardWindowsMinimized:
        debugLogAgent("unminimize app=\(app.localizedName ?? "unknown") reason=all-minimized")
        if !unminimizeFirstWindow(for: app) {
            debugLogAgent("unminimize failed app=\(app.localizedName ?? "unknown"); reopening")
            reopenApplication(for: app, verifyAfterReopen: true)
        }
    case .hasVisibleStandardWindow:
        debugLogAgent("skip app=\(app.localizedName ?? "unknown") reason=has-visible-window")
    }
}

func unminimizeFirstWindow(for app: NSRunningApplication) -> Bool {
    let axApp = AXUIElementCreateApplication(app.processIdentifier)

    var windowsRef: CFTypeRef?
    guard
        AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
            == .success,
        let windows = windowsRef as? [AXUIElement]
    else {
        return false
    }

    for window in windows {
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &roleRef)
        guard (roleRef as? String) == kAXWindowRole as String else { continue }

        if axBoolAttribute(kAXMinimizedAttribute as CFString, of: window) {
            let result = AXUIElementSetAttributeValue(
                window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
            debugLogAgent(
                "set minimized=false app=\(app.localizedName ?? "unknown") result=\(result.rawValue)"
            )
            return result == .success
        }
    }

    return false
}

func reopenApplication(for app: NSRunningApplication, verifyAfterReopen: Bool) {
    guard let bundleURL = app.bundleURL else {
        debugLogAgent("reopen fallback no bundleURL app=\(app.localizedName ?? "unknown")")
        openNewWindow(for: app)
        return
    }

    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = true
    configuration.createsNewApplicationInstance = false

    NSWorkspace.shared.openApplication(at: bundleURL, configuration: configuration) { _, error in
        if let error = error {
            logAgent(
                "reopen failed app=\(app.localizedName ?? "unknown") error=\(error.localizedDescription)"
            )
            openNewWindow(for: app)
            return
        }

        debugLogAgent("reopen requested app=\(app.localizedName ?? "unknown")")
        guard verifyAfterReopen else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            switch windowState(for: app) {
            case .unavailable, .noStandardWindows:
                debugLogAgent(
                    "openNewWindow app=\(app.localizedName ?? "unknown") reason=reopen-did-not-create-window"
                )
                openNewWindow(for: app)
            case .allStandardWindowsMinimized:
                _ = unminimizeFirstWindow(for: app)
            case .hasVisibleStandardWindow:
                break
            }
        }
    }
}

func openNewWindow(for app: NSRunningApplication) {
    debugLogAgent(
        "posting Cmd+N app=\(app.localizedName ?? "unknown") pid=\(app.processIdentifier)")
    let src = CGEventSource(stateID: .hidSystemState)
    guard let down = CGEvent(keyboardEventSource: src, virtualKey: nKeyCode, keyDown: true),
        let up = CGEvent(keyboardEventSource: src, virtualKey: nKeyCode, keyDown: false)
    else { return }
    down.flags = .maskCommand
    up.flags = .maskCommand
    down.postToPid(app.processIdentifier)
    up.postToPid(app.processIdentifier)
}
