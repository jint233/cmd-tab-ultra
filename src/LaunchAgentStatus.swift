import ApplicationServices
import Foundation

func launchctlPrint() -> String? {
    let result = runCommand("/bin/launchctl", ["print", serviceIdentifier])
    return result.status == 0 ? result.output : nil
}

func statusValue(_ key: String, in output: String) -> String? {
    for line in output.split(separator: "\n") {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("\(key) = ") {
            return String(trimmed.dropFirst(key.count + 3))
        }
    }
    return nil
}

private var cachedLaunchAgentVersion: String?

func invalidateLaunchAgentVersionCache() {
    cachedLaunchAgentVersion = nil
}

func launchAgentVersion() -> String? {
    if let cached = cachedLaunchAgentVersion { return cached }
    let result = runCommand("/usr/libexec/PlistBuddy", ["-c", "Print :Version", launchAgentPath])
    guard result.status == 0 else { return nil }
    let version = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
    cachedLaunchAgentVersion = version
    return version
}

func isAutoStartEnabled() -> Bool {
    guard FileManager.default.fileExists(atPath: launchAgentPath) else { return false }

    let result = runCommand("/bin/launchctl", ["print-disabled", serviceDomain])
    guard result.status == 0 else { return false }
    for line in result.output.split(separator: "\n") {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("\"\(serviceLabel)\" => ") {
            return trimmed.hasSuffix("enabled")
        }
    }

    // A loaded LaunchAgent without an explicit disabled override is enabled.
    return true
}

func currentServiceStatus() -> ServiceStatus {
    let output = launchctlPrint()
    let pid = output.flatMap { statusValue("pid", in: $0) }.flatMap(Int.init)
    let readyURL = URL(fileURLWithPath: agentReadyPath)
    let readyPid = (try? String(contentsOf: readyURL, encoding: .utf8))
        .flatMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }

    return ServiceStatus(
        loaded: output != nil,
        running: pid != nil,
        pid: pid,
        version: launchAgentVersion() ?? appVersion,
        autoStartEnabled: isAutoStartEnabled(),
        accessibilityGranted: AXIsProcessTrusted(),
        agentReady: pid != nil && readyPid == pid
    )
}
