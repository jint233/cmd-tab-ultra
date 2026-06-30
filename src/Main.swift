import ApplicationServices
import Cocoa

@main
struct CmdTabUltraApp {
    static func main() {
        // Disable stdout buffering so log output reaches the file immediately.
        setbuf(stdout, nil)

        if let relaunchIndex = CommandLine.arguments.firstIndex(of: relaunchArgument),
            CommandLine.arguments.indices.contains(relaunchIndex + 1)
        {
            Thread.sleep(forTimeInterval: 0.5)
            _ = runCommand("/usr/bin/open", [CommandLine.arguments[relaunchIndex + 1]])
            return
        }

        // Register app activation observer (shared by agent mode).
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard
                let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                    as? NSRunningApplication
            else { return }
            handleActivatedApplication(app)
        }

        if !CommandLine.arguments.contains(agentArgument) {
            let app = NSApplication.shared
            let delegate = ControlPanelDelegate()
            app.delegate = delegate
            app.run()
            return
        }

        requireAccessibility()
        installEventTapWhenAvailable()

        RunLoop.main.run()
    }
}
