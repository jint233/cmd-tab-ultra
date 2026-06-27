import Cocoa

extension ControlPanelDelegate {
    func refresh() {
        setControlsEnabled(false)
        setMessage("正在刷新…")
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
            status.accessibilityGranted ? "启动" : (startButton.title == "重启软件" ? "重启软件" : "去授权")

        if !status.accessibilityGranted {
            statusDot.stringValue = "●"
            statusDot.textColor = .systemOrange
            statusValue.stringValue = status.running ? "等待授权" : "未授权"
            statusValue.textColor = .systemOrange

            if startButton.title == "重启软件" {
                if !isMessageProtected {
                    messageValue.stringValue = "请在辅助功能设置中允许该应用。授权完成后会提示重启软件。"
                }
            } else if status.running {
                if !isMessageProtected {
                    messageValue.stringValue = "服务进程已启动，但辅助功能未授权，当前功能不会生效。请点击「去授权」进行设置。"
                }
            } else if !isMessageProtected {
                messageValue.stringValue = "使用此工具需要辅助功能权限，请点击「去授权」进行设置。"
            }

            startButton.isEnabled = true
            stopButton.isEnabled = false
        } else if status.running && status.agentReady {
            statusDot.stringValue = "●"
            statusDot.textColor = .systemGreen
            statusValue.stringValue = hasJustStarted ? "启动完成" : "服务运行中"
            statusValue.textColor = .systemGreen
            if !isMessageProtected
                && (messageValue.stringValue.hasPrefix("请在系统设置")
                    || messageValue.stringValue.hasPrefix("正在打开")
                    || messageValue.stringValue == "启动完成")
            {
                messageValue.stringValue = ""
            }

            startButton.isEnabled = false
            stopButton.isEnabled = true
        } else if status.running {
            statusDot.stringValue = "●"
            statusDot.textColor = .systemYellow
            statusValue.stringValue = "服务就绪中"
            statusValue.textColor = .systemYellow
            if !isMessageProtected
                && (messageValue.stringValue.isEmpty || messageValue.stringValue == "启动完成")
            {
                messageValue.stringValue = "服务进程已启动，但监听模块尚未就绪；请确认辅助功能授权已允许 CmdTabUltra。"
            }

            startButton.isEnabled = false
            stopButton.isEnabled = true
        } else {
            statusDot.stringValue = "●"
            statusDot.textColor = .systemRed
            statusValue.stringValue = "已停止"
            statusValue.textColor = .systemRed
            if !isMessageProtected
                && (messageValue.stringValue.hasPrefix("请在系统设置")
                    || messageValue.stringValue.hasPrefix("正在打开"))
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
            ? "无"
            : status.duplicatePids.map(String.init).joined(separator: ", ")
        autoStartSwitch.isEnabled = true
        autoStartSwitch.state = status.autoStartEnabled ? .on : .off
        refreshButton.isEnabled = true
    }
}
