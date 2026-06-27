import Cocoa

extension ControlPanelDelegate {
    func refresh() {
        setControlsEnabled(false)
        setMessage(localized("message.refreshing"))
        DispatchQueue.global(qos: .userInitiated).async {
            let status = currentServiceStatus()
            DispatchQueue.main.async {
                self.setMessage("")
                self.applyStatus(status)
            }
        }
    }

    func refreshSilently() {
        guard !isStarting && !isStopping else { return }
        guard startButton.isEnabled || stopButton.isEnabled else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let status = currentServiceStatus()
            DispatchQueue.main.async {
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
            DispatchQueue.main.async {
                self.promptRestartAfterAuthorization()
            }
            return
        }

        startButton.title =
            status.accessibilityGranted
            ? localized("control.start")
            : (startButton.title == localized("control.restart")
                ? localized("control.restart") : localized("control.authorize"))

        if !status.accessibilityGranted {
            statusDot.stringValue = "●"
            statusDot.textColor = .systemOrange
            statusValue.stringValue =
                status.running
                ? localized("state.waitingAuthorization") : localized("state.unauthorized")
            statusValue.textColor = .systemOrange

            if startButton.title == localized("control.restart") {
                if !isMessageProtected {
                    messageValue.stringValue = localized("message.allowAccessibilityThenRestart")
                }
            } else if status.running {
                if !isMessageProtected {
                    messageValue.stringValue = localized("message.serviceRunningUnauthorized")
                }
            } else if !isMessageProtected {
                messageValue.stringValue = localized("message.accessibilityRequired")
            }

            startButton.isEnabled = true
            stopButton.isEnabled = false
        } else if status.running && status.agentReady {
            statusDot.stringValue = "●"
            statusDot.textColor = .systemGreen
            statusValue.stringValue =
                hasJustStarted ? localized("state.started") : localized("state.running")
            statusValue.textColor = .systemGreen
            if !isMessageProtected
                && (messageValue.stringValue == localized("state.started")
                    || messageValue.stringValue == localized("message.openedAccessibility"))
            {
                messageValue.stringValue = ""
            }

            startButton.isEnabled = false
            stopButton.isEnabled = true
        } else if status.running {
            statusDot.stringValue = "●"
            statusDot.textColor = .systemYellow
            statusValue.stringValue = localized("state.readying")
            statusValue.textColor = .systemYellow
            if !isMessageProtected
                && (messageValue.stringValue.isEmpty
                    || messageValue.stringValue == localized("state.started"))
            {
                messageValue.stringValue = localized("message.agentNotReady")
            }

            startButton.isEnabled = false
            stopButton.isEnabled = true
        } else {
            statusDot.stringValue = "●"
            statusDot.textColor = .systemRed
            statusValue.stringValue = localized("state.stopped")
            statusValue.textColor = .systemRed
            if !isMessageProtected
                && messageValue.stringValue == localized("message.openedAccessibility")
            {
                messageValue.stringValue = ""
            }

            startButton.isEnabled = true
            stopButton.isEnabled = false
        }

        versionValue.stringValue = status.version ?? appVersion
        pidValue.stringValue = status.pid.map(String.init) ?? "—"
        duplicateValue.stringValue =
            status.duplicatePids.isEmpty
            ? localized("status.none")
            : status.duplicatePids.map(String.init).joined(separator: ", ")
        autoStartSwitch.isEnabled = true
        autoStartSwitch.state = status.autoStartEnabled ? .on : .off
        refreshButton.isEnabled = true
    }
}
