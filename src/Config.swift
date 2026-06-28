import Cocoa

let appName = "CmdTabUltra"
let serviceLabel = "com.jint233.cmdtabultra"
let agentArgument = "--agent"
let defaultVersion = "1.0.5"

let tabKeyCode: Int64 = 48
let nKeyCode: CGKeyCode = 0x2D

let skippedBundleIDs: Set<String> = [
    "com.apple.systemuiserver"
]

var appVersion: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        ?? defaultVersion
}

var serviceDomain: String {
    "gui/\(getuid())"
}

var serviceIdentifier: String {
    "\(serviceDomain)/\(serviceLabel)"
}

var launchAgentPath: String {
    "\(NSHomeDirectory())/Library/LaunchAgents/\(serviceLabel).plist"
}

var installedBinaryPath: String {
    Bundle.main.executableURL?.path
        ?? "\(NSHomeDirectory())/Applications/\(appName).app/Contents/MacOS/\(appName)"
}

var userApplicationsInstallPath: String {
    "\(NSHomeDirectory())/Applications/\(appName).app"
}

var agentReadyPath: String {
    "\(NSHomeDirectory())/Library/Application Support/\(appName)/agent-ready"
}

struct ServiceStatus {
    let loaded: Bool
    let running: Bool
    let pid: Int?
    let runs: Int?
    let program: String?
    let version: String?
    let autoStartEnabled: Bool
    let duplicatePids: [Int]
    let accessibilityGranted: Bool
    let agentReady: Bool
}
