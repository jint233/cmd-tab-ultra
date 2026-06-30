import Cocoa

extension ControlPanelDelegate {
    func refresh() {
        setControlsEnabled(false)
        setMessage(localized("message.refreshing"))
        DispatchQueue.global(qos: .userInitiated).async {
            let status = currentServiceStatus()
            DispatchQueue.main.async { [weak self] in
                self?.setMessage("")
                self?.applyStatus(status)
            }
        }
    }

    func refreshSilently() {
        guard !isStarting && !isStopping else { return }
        guard startButton.isEnabled || stopButton.isEnabled else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let status = currentServiceStatus()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if !self.isStarting && !self.isStopping
                    && (self.startButton.isEnabled || self.stopButton.isEnabled)
                {
                    self.applyStatus(status)
                }
            }
        }
    }

    func applyStatus(_ status: ServiceStatus) {
        if authorizationFlowStarted && status.accessibilityGranted {
            promptRestartAfterAuthorization()
            return
        }

        if !status.accessibilityGranted {
            if primaryAction != .restart {
                primaryAction = .authorize
            }
            applyPrimaryActionTitle()
            applyPrimaryButtonStyle(isServiceRunning: false)
            statusDot.stringValue = "●"
            statusDot.textColor = .systemOrange
            statusValue.stringValue =
                status.running
                ? localized("state.waitingAuthorization") : localized("state.unauthorized")
            statusValue.textColor = .systemOrange

            if primaryAction == .restart {
                statusDescription.stringValue = localized("message.allowAccessibilityThenRestart")
            } else if status.running {
                statusDescription.stringValue = localized("message.serviceRunningUnauthorized")
            } else {
                statusDescription.stringValue = localized("message.accessibilityRequired")
            }

            startButton.isEnabled = true
            stopButton.isEnabled = false
        } else if status.running && status.agentReady {
            primaryAction = .start
            applyPrimaryActionTitle()
            applyPrimaryButtonStyle(isServiceRunning: true)
            statusDot.stringValue = "●"
            statusDot.textColor = .systemGreen
            statusValue.stringValue =
                hasJustStarted ? localized("state.started") : localized("state.running")
            statusValue.textColor = .systemGreen
            statusDescription.stringValue = localized("description.running")

            startButton.isEnabled = false
            stopButton.isEnabled = true
        } else if status.running {
            primaryAction = .start
            applyPrimaryActionTitle()
            applyPrimaryButtonStyle(isServiceRunning: true)
            statusDot.stringValue = "●"
            statusDot.textColor = .systemYellow
            statusValue.stringValue = localized("state.readying")
            statusValue.textColor = .systemYellow
            statusDescription.stringValue = localized("message.agentNotReady")

            startButton.isEnabled = false
            stopButton.isEnabled = true
        } else {
            primaryAction = .start
            applyPrimaryActionTitle()
            applyPrimaryButtonStyle(isServiceRunning: false)
            statusDot.stringValue = "●"
            statusDot.textColor = .systemRed
            statusValue.stringValue = localized("state.stopped")
            statusValue.textColor = .systemRed
            statusDescription.stringValue = localized("description.stopped")

            startButton.isEnabled = true
            stopButton.isEnabled = false
        }

        if isMessageProtected {
            statusDescription.stringValue = messageText
        }

        versionValue.stringValue = status.version ?? appVersion
        updatePreferenceControls()
        updateRecentActions()
        autoStartSwitch.isEnabled = true
        restoreMinimizedSwitch.isEnabled = true
        reopenWindowsSwitch.isEnabled = true
        commandNFallbackSwitch.isEnabled = true
        chooseExcludedAppButton.isEnabled = true
        excludedBundleIDTable.isEnabled = true
        updateExcludedAppSelection()
        autoStartSwitch.state = status.autoStartEnabled ? .on : .off
        refreshButton.isEnabled = true
    }
}
