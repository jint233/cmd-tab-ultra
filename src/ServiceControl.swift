import Foundation

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
    let command = enabled ? "enable" : "disable"
    let result = runCommand("/bin/launchctl", [command, serviceIdentifier])
    return result.status == 0
        ? (enabled ? "Auto-start enabled" : "Auto-start disabled") : result.output
}
