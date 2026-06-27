import Cocoa

final class CmdTabSwitchState {
    private var cmdTabWasPressed = false
    private var expectingSwitch = false
    private var currentSwitchID = 0
    private var consumedSwitchID = 0
    private var pendingActivatedApplication: NSRunningApplication?

    func handleActivatedApplication(_ app: NSRunningApplication) {
        debugLogAgent(
            "activated app=\(app.localizedName ?? "unknown") bundle=\(app.bundleIdentifier ?? "nil") pid=\(app.processIdentifier) cmdTabWasPressed=\(cmdTabWasPressed) expectingSwitch=\(expectingSwitch) switchID=\(currentSwitchID)"
        )
        guard cmdTabWasPressed || expectingSwitch else { return }

        pendingActivatedApplication = app
        if expectingSwitch {
            let switchID = currentSwitchID
            DispatchQueue.main.async {
                self.restorePendingSwitchTarget(for: switchID)
            }
        }
    }

    func handleTabKeyDown(keyCode: Int64, flags: CGEventFlags) {
        guard keyCode == tabKeyCode && flags.contains(.maskCommand) else { return }

        // Cmd+Shift+Tab is intentionally supported: it is still Tab with Command held.
        if !cmdTabWasPressed && !expectingSwitch {
            currentSwitchID += 1
            pendingActivatedApplication = nil
        }
        cmdTabWasPressed = true
    }

    func handleFlagsChanged(flags: CGEventFlags) {
        guard !flags.contains(.maskCommand) && cmdTabWasPressed else { return }

        cmdTabWasPressed = false
        expectingSwitch = true
        let switchID = currentSwitchID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.restorePendingSwitchTarget(for: switchID)
        }
    }

    private func restorePendingSwitchTarget(for switchID: Int) {
        guard switchID == currentSwitchID else { return }
        guard expectingSwitch else { return }
        guard consumedSwitchID != switchID else { return }

        consumedSwitchID = switchID
        expectingSwitch = false

        let app = pendingActivatedApplication ?? NSWorkspace.shared.frontmostApplication
        pendingActivatedApplication = nil

        guard let app else { return }
        ensureVisibleWindow(app: app)
    }
}

let cmdTabSwitchState = CmdTabSwitchState()

func handleActivatedApplication(_ app: NSRunningApplication) {
    cmdTabSwitchState.handleActivatedApplication(app)
}
