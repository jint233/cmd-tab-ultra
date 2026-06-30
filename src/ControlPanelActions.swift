import ApplicationServices
import Cocoa
import UniformTypeIdentifiers

extension ControlPanelDelegate {
    func setControlsEnabled(_ enabled: Bool) {
        startButton.isEnabled = enabled
        stopButton.isEnabled = enabled
        refreshButton.isEnabled = enabled
        autoStartSwitch.isEnabled = enabled
        restoreMinimizedSwitch.isEnabled = enabled
        reopenWindowsSwitch.isEnabled = enabled
        commandNFallbackSwitch.isEnabled = enabled
        chooseExcludedAppButton.isEnabled = enabled
        excludedBundleIDTable.isEnabled = enabled
        removeExcludedButton.isEnabled = enabled
    }

    func relaunchApplication() {
        let appPath = Bundle.main.bundleURL.path
        guard let executableURL = Bundle.main.executableURL else {
            NSApp.terminate(nil)
            return
        }

        let process = Process()
        process.executableURL = executableURL
        process.arguments = [relaunchArgument, appPath]

        do {
            try process.run()
        } catch {
            print("Failed to schedule relaunch: \(error)")
        }

        NSApp.terminate(nil)
    }

    func promptRestartAfterAuthorization() {
        guard !restartPromptShown else { return }
        restartPromptShown = true

        let alert = NSAlert()
        alert.messageText = localized("alert.restart.title")
        alert.informativeText = localized("alert.restart.message")
        alert.alertStyle = .informational
        alert.addButton(withTitle: localized("control.restart"))
        alert.runModal()
        relaunchApplication()
    }

    func setMessage(_ text: String, protectingFor seconds: TimeInterval = 0) {
        messageText = text
        protectedMessageUntil = seconds > 0 ? Date().addingTimeInterval(seconds) : nil
        if !text.isEmpty {
            statusDescription.stringValue = text
        }
    }

    var isMessageProtected: Bool {
        guard let protectedMessageUntil else { return false }
        if Date() < protectedMessageUntil {
            return true
        }
        self.protectedMessageUntil = nil
        return false
    }

    @objc func refreshClicked() {
        hasJustStarted = false
        setMessage("")
        refresh()
    }

    func prepareAccessibilityAuthorization(message: String, setRestartAction: Bool) {
        authorizationFlowStarted = true
        setControlsEnabled(false)
        setMessage(message, protectingFor: 3)

        if setRestartAction {
            primaryAction = .restart
            applyPrimaryActionTitle()
        }

        DispatchQueue.global(qos: .userInitiated).async {
            _ = stopService()
            resetAccessibilityPermission()
            let status = currentServiceStatus()

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if setRestartAction {
                    self.primaryAction = .restart
                    self.applyPrimaryActionTitle()
                }
                self.applyStatus(status)
                self.setMessage(message, protectingFor: 3)

                let opts =
                    [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                    as CFDictionary
                _ = AXIsProcessTrustedWithOptions(opts)
                self.startAuthorizationPolling()
            }
        }
    }

    @objc func startClicked() {
        DispatchQueue.global(qos: .userInitiated).async {
            removeDuplicateUserInstallIfNeeded()
            let status = currentServiceStatus()
            DispatchQueue.main.async { [weak self] in
                self?.handleStartClick(with: status)
            }
        }
    }

    private func handleStartClick(with status: ServiceStatus) {
        if !status.accessibilityGranted {
            if primaryAction == .restart {
                DispatchQueue.global(qos: .userInitiated).async {
                    let refreshedStatus = currentServiceStatus()
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        if refreshedStatus.accessibilityGranted {
                            self.promptRestartAfterAuthorization()
                        } else {
                            self.prepareAccessibilityAuthorization(
                                message: localized("message.allowAccessibilityFirst"),
                                setRestartAction: true
                            )
                        }
                    }
                }
                return
            }

            restartPromptShown = false
            prepareAccessibilityAuthorization(
                message: localized("message.openedAccessibility"),
                setRestartAction: true
            )
            return
        }

        startServiceFromControlPanel()
    }

    private func startServiceFromControlPanel() {
        isStarting = true
        setControlsEnabled(false)
        setMessage(localized("message.starting"))
        statusDot.stringValue = "●"
        statusDot.textColor = .systemYellow
        statusValue.stringValue = localized("state.readying")
        statusValue.textColor = .systemYellow
        statusDescription.stringValue = localized("description.readying")
        applyPrimaryButtonStyle(isServiceRunning: true)

        DispatchQueue.global(qos: .userInitiated).async {
            let msg = startService()
            let newStatus = currentServiceStatus()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                guard let self else { return }
                self.isStarting = false
                if msg == "Started" && newStatus.agentReady {
                    self.hasJustStarted = true
                    self.setMessage(localized("state.started"), protectingFor: 4)
                } else if msg == "Started" {
                    self.hasJustStarted = false
                    self.setMessage(
                        newStatus.accessibilityGranted
                            ? localized("message.startedWaitingAgent")
                            : localized("message.startedUnauthorized"), protectingFor: 4)
                } else {
                    self.setMessage(msg, protectingFor: 4)
                }
                self.applyStatus(newStatus)
            }
        }
    }

    @objc func stopClicked() {
        hasJustStarted = false
        isStopping = true
        setControlsEnabled(false)
        setMessage(localized("message.stopping"))

        statusDot.stringValue = "●"
        statusDot.textColor = .systemYellow
        statusValue.stringValue = localized("state.stopping")
        statusValue.textColor = .systemYellow
        statusDescription.stringValue = localized("description.stopping")
        applyPrimaryButtonStyle(isServiceRunning: false)

        DispatchQueue.global(qos: .userInitiated).async {
            let msg = stopService()
            let newStatus = currentServiceStatus()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self else { return }
                self.isStopping = false
                self.setMessage(
                    msg == "Stopped" ? localized("state.stopped") : msg,
                    protectingFor: 3
                )
                self.applyStatus(newStatus)
            }
        }
    }

    @objc func toggleAutoStart() {
        let shouldEnableAutoStart = autoStartSwitch.state == .on
        setControlsEnabled(false)
        DispatchQueue.global(qos: .userInitiated).async {
            let msg = setAutoStartEnabled(shouldEnableAutoStart)
            let status = currentServiceStatus()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let zhMsg: String
                switch msg {
                case "Auto-start enabled": zhMsg = localized("message.autoStartEnabled")
                case "Auto-start disabled": zhMsg = localized("message.autoStartDisabled")
                default: zhMsg = msg
                }
                self.setMessage(zhMsg, protectingFor: 3)
                self.applyStatus(status)
            }
        }
    }

    @objc func toggleRestorePolicy() {
        AppPreferences.setRestoreMinimizedWindows(restoreMinimizedSwitch.state == .on)
        AppPreferences.setReopenAppsWithoutWindows(reopenWindowsSwitch.state == .on)
        AppPreferences.setUseCommandNFallback(commandNFallbackSwitch.state == .on)
        setMessage(localized("message.preferencesSaved"), protectingFor: 2)
        refreshSilently()
    }

    @objc func chooseExcludedApp() {
        let panel = NSOpenPanel()
        panel.title = localized("excluded.chooseTitle")
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [.application]
        } else {
            panel.allowedFileTypes = ["app"]
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        guard panel.runModal() == .OK else { return }
        guard let url = panel.url,
            let bundle = Bundle(url: url),
            let bundleID = bundle.bundleIdentifier
        else {
            setMessage(localized("message.chooseValidApp"), protectingFor: 2)
            return
        }
        AppPreferences.addExcludedBundleID(bundleID)
        updateExcludedBundleIDList(selecting: bundleID)
        setMessage(localized("message.excludedAppAdded"), protectingFor: 2)
    }

    @objc func removeExcludedBundleID() {
        let selectedRow = excludedBundleIDTable.selectedRow
        guard excludedBundleIDsSnapshot.indices.contains(selectedRow) else { return }
        let bundleID = excludedBundleIDsSnapshot[selectedRow]
        if defaultExcludedBundleIDs.contains(bundleID) {
            setMessage(localized("message.defaultExclusionLocked"), protectingFor: 2)
            return
        }
        AppPreferences.removeExcludedBundleID(bundleID)
        updateExcludedBundleIDList()
        setMessage(localized("message.excludedAppRemoved"), protectingFor: 2)
    }

    @objc func clearLogsClicked() {
        clearRecentActionRecords()
        updateRecentActions()
    }
}
