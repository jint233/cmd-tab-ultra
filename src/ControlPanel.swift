import Cocoa

final class ControlPanelDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let statusDot = NSTextField(labelWithString: "")
    let statusValue = NSTextField(labelWithString: "")
    let versionValue = NSTextField(labelWithString: "")
    let pidValue = NSTextField(labelWithString: "")
    let duplicateValue = NSTextField(labelWithString: "")
    let autoStartSwitch = NSSwitch()
    let startButton = NSButton(title: "", target: nil, action: nil)
    let stopButton = NSButton(title: "", target: nil, action: nil)
    let refreshButton = NSButton(title: "", target: nil, action: nil)
    let messageValue = NSTextField(labelWithString: "")
    var refreshTimer: Timer?
    var isStarting = false
    var isStopping = false
    var hasJustStarted = false
    var authorizationFlowStarted = false
    var restartPromptShown = false
    var protectedMessageUntil: Date?

    // MARK: NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        startButton.title = localized("control.start")
        stopButton.title = localized("control.stop")
        refreshButton.title = localized("control.refresh")

        NSApp.setActivationPolicy(.regular)
        buildWindow()
        refresh()
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.refreshSilently()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        refreshTimer?.invalidate()
        return true
    }
}
