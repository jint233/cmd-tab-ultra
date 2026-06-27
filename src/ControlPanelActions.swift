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
        alert.messageText = "需要重启软件"
        alert.informativeText = "辅助功能权限已授权。为确保新的权限状态生效，请重启 CmdTabUltra。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "重启软件")
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
        let status = currentServiceStatus()
        if !status.accessibilityGranted {
            if startButton.title == "重启软件" {
                let refreshedStatus = currentServiceStatus()
                if refreshedStatus.accessibilityGranted {
                    promptRestartAfterAuthorization()
                } else {
                    authorizationFlowStarted = true
                    setMessage("请先在辅助功能设置中允许该应用，授权完成后会提示重启软件。", protectingFor: 3)
                    let opts =
                        [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                        as CFDictionary
                    _ = AXIsProcessTrustedWithOptions(opts)
                }
                return
            }

            authorizationFlowStarted = true
            restartPromptShown = false
            setMessage("已打开辅助功能设置。授权完成后会提示重启软件。", protectingFor: 3)
            let opts =
                [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(opts)
            startButton.title = "重启软件"
            return
        }

        isStarting = true
        setControlsEnabled(false)
        setMessage("正在启动服务…")

        statusDot.stringValue = "●"
        statusDot.textColor = .systemYellow
        statusValue.stringValue = "服务就绪中"
        statusValue.textColor = .systemYellow

        DispatchQueue.global(qos: .userInitiated).async {
            let msg = startService()
            Thread.sleep(forTimeInterval: 0.8)
            let newStatus = currentServiceStatus()
            DispatchQueue.main.async {
                self.isStarting = false
                if msg == "Started" && newStatus.agentReady {
                    self.hasJustStarted = true
                    self.setMessage("启动完成", protectingFor: 4)
                } else if msg == "Started" {
                    self.hasJustStarted = false
                    self.setMessage(
                        newStatus.accessibilityGranted
                            ? "服务已启动，正在等待监听模块就绪。"
                            : "服务已启动，但辅助功能未授权，功能暂不可用。", protectingFor: 4)
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
        setMessage("正在停止服务…")

        statusDot.stringValue = "●"
        statusDot.textColor = .systemYellow
        statusValue.stringValue = "停止中"
        statusValue.textColor = .systemYellow

        DispatchQueue.global(qos: .userInitiated).async {
            let msg = stopService()
            Thread.sleep(forTimeInterval: 0.6)
            let newStatus = currentServiceStatus()
            DispatchQueue.main.async {
                self.isStopping = false
                self.setMessage(msg == "Stopped" ? "已停止" : msg, protectingFor: 3)
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
                case "Auto-start enabled": zhMsg = "已开启开机自启"
                case "Auto-start disabled": zhMsg = "已关闭开机自启"
                default: zhMsg = msg
                }
                self.setMessage(zhMsg, protectingFor: 3)
                self.applyStatus(status)
            }
        }
    }
}
