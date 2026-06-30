import Cocoa

let appName = "CmdTabUltra"
let appDisplayName = "Cmd-Tab-Ultra"
let serviceLabel = "com.jint233.cmdtabultra"
let agentArgument = "--agent"
let relaunchArgument = "--relaunch"
let defaultVersion = "0.0.0"

let tabKeyCode: Int64 = 48
let nKeyCode: CGKeyCode = 0x2D

let appVersion: String = {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        ?? defaultVersion
}()

let serviceDomain: String = "gui/\(getuid())"

let serviceIdentifier: String = {
    "\(serviceDomain)/\(serviceLabel)"
}()

let launchAgentPath: String = {
    "\(NSHomeDirectory())/Library/LaunchAgents/\(serviceLabel).plist"
}()

let installedBinaryPath: String = {
    Bundle.main.executableURL?.path
        ?? "\(NSHomeDirectory())/Applications/\(appName).app/Contents/MacOS/\(appName)"
}()

let userApplicationsInstallPath: String = {
    "\(NSHomeDirectory())/Applications/\(appName).app"
}()

let agentReadyPath: String = {
    "\(applicationSupportDirectoryPath)/agent-ready"
}()

struct ServiceStatus {
    let loaded: Bool
    let running: Bool
    let pid: Int?
    let version: String?
    let autoStartEnabled: Bool
    let accessibilityGranted: Bool
    let agentReady: Bool
}
