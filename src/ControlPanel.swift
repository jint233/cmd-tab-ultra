import Cocoa

enum ControlPanelPrimaryAction {
    case start
    case authorize
    case restart
}

final class ControlPanelDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let languageLabel = NSTextField(labelWithString: "")
    let languagePopup = NSPopUpButton()
    let statusDot = NSTextField(labelWithString: "")
    let statusValue = NSTextField(labelWithString: "")
    let statusDescription = NSTextField(labelWithString: "")
    let versionLabel = NSTextField(labelWithString: "")
    let pidLabel = NSTextField(labelWithString: "")
    let duplicateLabel = NSTextField(labelWithString: "")
    let autoStartLabel = NSTextField(labelWithString: "")
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
    var primaryAction: ControlPanelPrimaryAction = .start

    // MARK: NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        buildWindow()
        applyLocalizedText()
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
