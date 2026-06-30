import ApplicationServices
import Cocoa

func ensureVisibleWindow(app: NSRunningApplication) {
    debugLogAgent(
        "ensure app=\(app.localizedName ?? "unknown") bundle=\(app.bundleIdentifier ?? "nil") pid=\(app.processIdentifier) policy=\(app.activationPolicy.rawValue)"
    )
    if AppPreferences.isBundleExcluded(app.bundleIdentifier) {
        return
    }
    guard app.activationPolicy == .regular else {
        return
    }

    let policy = AppPreferences.restorePolicy
    switch windowState(for: app) {
    case .unavailable, .noStandardWindows:
        guard policy.reopenAppsWithoutWindows else {
            return
        }
        debugLogAgent(
            "reopen app=\(app.localizedName ?? "unknown") reason=no-window-or-unavailable")
        reopenApplication(for: app, verifyAfterReopen: true)
    case .allStandardWindowsMinimized:
        guard policy.restoreMinimizedWindows else {
            return
        }
        debugLogAgent("unminimize app=\(app.localizedName ?? "unknown") reason=all-minimized")
        if unminimizeFirstWindow(for: app) {
            recordAction(for: app, action: .unminimized, result: "Restored minimized window")
        } else {
            debugLogAgent("unminimize failed app=\(app.localizedName ?? "unknown"); reopening")
            if policy.reopenAppsWithoutWindows {
                reopenApplication(for: app, verifyAfterReopen: true)
            } else {
                recordAction(for: app, action: .failed, result: "Failed to restore window")
            }
        }
    case .hasVisibleStandardWindow:
        debugLogAgent("skip app=\(app.localizedName ?? "unknown") reason=has-visible-window")
    }
}

func unminimizeFirstWindow(for app: NSRunningApplication) -> Bool {
    let axApp = appAccessibilityElement(for: app)

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
        _ = openNewWindow(for: app)
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
            if AppPreferences.restorePolicy.useCommandNFallback {
                if !openNewWindow(for: app) {
                    recordAction(for: app, action: .failed, result: error.localizedDescription)
                }
            } else {
                recordAction(for: app, action: .failed, result: error.localizedDescription)
            }
            return
        }

        debugLogAgent("reopen requested app=\(app.localizedName ?? "unknown")")
        recordAction(for: app, action: .reopened, result: "Requested app reopen")
        guard verifyAfterReopen else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard !app.isTerminated else { return }
            switch windowState(for: app) {
            case .unavailable, .noStandardWindows:
                debugLogAgent(
                    "openNewWindow app=\(app.localizedName ?? "unknown") reason=reopen-did-not-create-window"
                )
                if AppPreferences.restorePolicy.useCommandNFallback {
                    if !openNewWindow(for: app) {
                        recordAction(
                            for: app, action: .failed, result: "Reopen did not create window")
                    }
                } else {
                    recordAction(for: app, action: .failed, result: "New window creation disabled")
                }
            case .allStandardWindowsMinimized:
                if unminimizeFirstWindow(for: app) {
                    recordAction(
                        for: app, action: .unminimized, result: "Restored minimized window")
                } else {
                    recordAction(for: app, action: .failed, result: "Failed to restore window")
                }
            case .hasVisibleStandardWindow:
                break
            }
        }
    }
}

func openNewWindow(for app: NSRunningApplication) -> Bool {
    guard AppPreferences.restorePolicy.useCommandNFallback else {
        return false
    }
    debugLogAgent(
        "posting Cmd+N app=\(app.localizedName ?? "unknown") pid=\(app.processIdentifier)")
    let src = CGEventSource(stateID: .hidSystemState)
    guard let down = CGEvent(keyboardEventSource: src, virtualKey: nKeyCode, keyDown: true),
        let up = CGEvent(keyboardEventSource: src, virtualKey: nKeyCode, keyDown: false)
    else { return false }
    down.flags = .maskCommand
    up.flags = .maskCommand
    down.postToPid(app.processIdentifier)
    up.postToPid(app.processIdentifier)
    recordAction(for: app, action: .cmdN, result: "Requested new window")
    return true
}

func recordAction(for app: NSRunningApplication, action: RecentActionKind, result: String) {
    appendRecentAction(
        appName: app.localizedName,
        bundleIdentifier: app.bundleIdentifier,
        action: action,
        result: result
    )
}
