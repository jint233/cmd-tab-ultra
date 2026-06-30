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
    let autoStartLabel = NSTextField(labelWithString: "")
    let restoreMinimizedLabel = NSTextField(labelWithString: "")
    let reopenWindowsLabel = NSTextField(labelWithString: "")
    let commandNFallbackLabel = NSTextField(labelWithString: "")
    let excludedAppsLabel = NSTextField(labelWithString: "")
    let excludedBundleIDTable = NSTableView()
    let excludedBundleIDScrollView = NSScrollView()
    let chooseExcludedAppButton = NSButton(title: "", target: nil, action: nil)
    let removeExcludedButton = NSButton(title: "", target: nil, action: nil)
    let clearLogsButton = NSButton(title: "", target: nil, action: nil)
    let recentActionsLabel = NSTextField(labelWithString: "")
    let recentActionsValue = NSTextField(labelWithString: "")
    let versionValue = NSTextField(labelWithString: "")
    let autoStartSwitch = NSSwitch()
    let restoreMinimizedSwitch = NSSwitch()
    let reopenWindowsSwitch = NSSwitch()
    let commandNFallbackSwitch = NSSwitch()
    let startButton = NSButton(title: "", target: nil, action: nil)
    let stopButton = NSButton(title: "", target: nil, action: nil)
    let refreshButton = NSButton(title: "", target: nil, action: nil)
    let messageValue = NSTextField(labelWithString: "")
    let tabSegmentedControl = RoundedTabSegmentedControl()
    let tabView = NSTabView()
    var excludedBundleIDsSnapshot: [String] = []
    var refreshTimer: Timer?
    var authorizationPollingTimer: Timer?
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

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.refreshSilently()
        }
    }

    func startAuthorizationPolling() {
        authorizationPollingTimer?.invalidate()
        authorizationPollingTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0, repeats: true
        ) { [weak self] _ in
            guard let self, self.authorizationFlowStarted else {
                self?.stopAuthorizationPolling()
                return
            }
            if AXIsProcessTrusted() {
                self.stopAuthorizationPolling()
                DispatchQueue.global(qos: .userInitiated).async {
                    let status = currentServiceStatus()
                    DispatchQueue.main.async { self.applyStatus(status) }
                }
            }
        }
    }

    func stopAuthorizationPolling() {
        authorizationPollingTimer?.invalidate()
        authorizationPollingTimer = nil
        // Restore normal timer if needed
        if refreshTimer == nil {
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) {
                [weak self] _ in
                self?.refreshSilently()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        refreshTimer?.invalidate()
        refreshTimer = nil
        authorizationPollingTimer?.invalidate()
        authorizationPollingTimer = nil
        return true
    }

    deinit {
        refreshTimer?.invalidate()
        refreshTimer = nil
        authorizationPollingTimer?.invalidate()
        authorizationPollingTimer = nil
    }
}
