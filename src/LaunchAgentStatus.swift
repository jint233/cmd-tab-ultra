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

func launchAgentVersion() -> String? {
    let result = runCommand("/usr/libexec/PlistBuddy", ["-c", "Print :Version", launchAgentPath])
    guard result.status == 0 else { return nil }
    return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
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
    let pids = agentPids()
    let duplicatePids = pids.filter { pid == nil || $0 != pid }
    let readyURL = URL(fileURLWithPath: agentReadyPath)
    let readyPid = (try? String(contentsOf: readyURL, encoding: .utf8))
        .flatMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }

    return ServiceStatus(
        loaded: output != nil,
        running: pid != nil,
        pid: pid,
        runs: output.flatMap { statusValue("runs", in: $0) }.flatMap(Int.init),
        program: output.flatMap { statusValue("program", in: $0) },
        version: launchAgentVersion() ?? appVersion,
        autoStartEnabled: isAutoStartEnabled(),
        duplicatePids: duplicatePids,
        accessibilityGranted: AXIsProcessTrusted(),
        agentReady: pid != nil && readyPid == pid
    )
}
