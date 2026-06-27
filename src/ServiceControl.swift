import Foundation

func removeDuplicateUserInstallIfNeeded() {
    let currentBundleURL = Bundle.main.bundleURL.standardizedFileURL
    let userApplicationsURL = URL(fileURLWithPath: userApplicationsInstallPath).standardizedFileURL
    guard currentBundleURL.path != userApplicationsURL.path else { return }
    guard FileManager.default.fileExists(atPath: userApplicationsURL.path) else { return }

    try? FileManager.default.removeItem(at: userApplicationsURL)
}

func writeLaunchAgentPlist(binaryPath: String = installedBinaryPath) throws {
    let plist: [String: Any] = [
        "Label": serviceLabel,
        "Version": appVersion,
        "ProgramArguments": [binaryPath, agentArgument],
        "RunAtLoad": true,
        "KeepAlive": true,
        "StandardOutPath": "/tmp/\(appName).log",
        "StandardErrorPath": "/tmp/\(appName).log",
    ]

    let data = try PropertyListSerialization.data(
        fromPropertyList: plist,
        format: .xml,
        options: 0
    )
    let url = URL(fileURLWithPath: launchAgentPath)
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try data.write(to: url, options: .atomic)
}

@discardableResult
func stopService() -> String {
    let status = currentServiceStatus()
    try? FileManager.default.removeItem(atPath: agentReadyPath)
    _ = runCommand("/bin/launchctl", ["bootout", serviceDomain, launchAgentPath])
    terminateDuplicateAgents(keeping: nil)
    if let pid = status.pid {
        kill(pid_t(pid), SIGTERM)
    }
    return "Stopped"
}

@discardableResult
func startService() -> String {
    let status = currentServiceStatus()
    try? FileManager.default.removeItem(atPath: agentReadyPath)
    if status.loaded {
        _ = runCommand("/bin/launchctl", ["bootout", serviceDomain, launchAgentPath])
    }
    removeDuplicateUserInstallIfNeeded()
    do {
        try writeLaunchAgentPlist()
    } catch {
        return "Failed to write LaunchAgent: \(error.localizedDescription)"
    }
    terminateDuplicateAgents(keeping: nil)
    _ = runCommand("/bin/launchctl", ["enable", serviceIdentifier])
    let bootstrap = runCommand("/bin/launchctl", ["bootstrap", serviceDomain, launchAgentPath])
    if bootstrap.status != 0 {
        return bootstrap.output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) {
        let refreshed = currentServiceStatus()
        terminateDuplicateAgents(keeping: refreshed.pid)
    }
    return "Started"
}

@discardableResult
func setAutoStartEnabled(_ enabled: Bool) -> String {
    if enabled {
        do {
            try writeLaunchAgentPlist()
        } catch {
            return "Failed to write LaunchAgent: \(error.localizedDescription)"
        }
    }

    let command = enabled ? "enable" : "disable"
    let result = runCommand("/bin/launchctl", [command, serviceIdentifier])
    return result.status == 0
        ? (enabled ? "Auto-start enabled" : "Auto-start disabled") : result.output
}
