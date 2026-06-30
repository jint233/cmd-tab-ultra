import ApplicationServices
import Cocoa

extension ControlPanelDelegate {
    func setControlsEnabled(_ enabled: Bool) {
        startButton.isEnabled = enabled
        stopButton.isEnabled = enabled
        refreshButton.isEnabled = enabled
        autoStartSwitch.isEnabled = enabled
    }

    func relaunchApplication() {
        let appPath = Bundle.main.bundleURL.path
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.environment = ["CMDTABULTRA_APP_PATH": appPath]
        process.arguments = [
            "-c",
            "sleep 0.5; /usr/bin/open \"$CMDTABULTRA_APP_PATH\"",
        ]

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
        messageValue.stringValue = text
        protectedMessageUntil = seconds > 0 ? Date().addingTimeInterval(seconds) : nil
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

    @objc func startClicked() {
        removeDuplicateUserInstallIfNeeded()

        let status = currentServiceStatus()
        if !status.accessibilityGranted {
            if primaryAction == .restart {
                let refreshedStatus = currentServiceStatus()
                if refreshedStatus.accessibilityGranted {
                    promptRestartAfterAuthorization()
                } else {
                    authorizationFlowStarted = true
                    setMessage(localized("message.allowAccessibilityFirst"), protectingFor: 3)
                    resetAccessibilityPermission()
                    let opts =
                        [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                        as CFDictionary
                    _ = AXIsProcessTrustedWithOptions(opts)
                }
                return
            }

            authorizationFlowStarted = true
            restartPromptShown = false
            setMessage(localized("message.openedAccessibility"), protectingFor: 3)
            resetAccessibilityPermission()
            let opts =
                [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(opts)
            primaryAction = .restart
            applyPrimaryActionTitle()
            return
        }

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
            Thread.sleep(forTimeInterval: 0.8)
            let newStatus = currentServiceStatus()
            DispatchQueue.main.async {
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
            Thread.sleep(forTimeInterval: 0.6)
            let newStatus = currentServiceStatus()
            DispatchQueue.main.async {
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
            DispatchQueue.main.async {
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
}
