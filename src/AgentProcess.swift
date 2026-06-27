import Foundation

func agentPids() -> [Int] {
    let result = runCommand("/bin/ps", ["-axo", "pid=,command="])
    guard result.status == 0 else { return [] }

    return result.output.split(separator: "\n").compactMap { line in
        let text = line.trimmingCharacters(in: .whitespaces)
        guard let firstSpace = text.firstIndex(where: { $0 == " " || $0 == "\t" }) else {
            return nil
        }
        let pidText = text[..<firstSpace]
        let command = text[firstSpace...].trimmingCharacters(in: .whitespaces)
        guard command == "\(installedBinaryPath) \(agentArgument)" else { return nil }
        return Int(pidText)
    }
}

func terminateDuplicateAgents(keeping keepPid: Int?) {
    for pid in agentPids() where pid != keepPid {
        kill(pid_t(pid), SIGTERM)
    }
}
