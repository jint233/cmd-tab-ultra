import Foundation

@discardableResult
func runCommand(
    _ executable: String,
    _ arguments: [String],
    timeout: TimeInterval = 5.0
) -> (status: Int32, output: String) {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = pipe
    process.standardError = pipe

    do {
        try process.run()
    } catch {
        return (1, error.localizedDescription)
    }

    let timeoutLock = NSLock()
    var didTimeOut = false
    let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
    timer.schedule(deadline: .now() + timeout)
    timer.setEventHandler {
        guard process.isRunning else { return }
        timeoutLock.lock()
        didTimeOut = true
        timeoutLock.unlock()
        process.terminate()
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1.0) {
            if process.isRunning {
                kill(process.processIdentifier, SIGKILL)
            }
        }
    }
    timer.resume()

    // Read before waiting so a verbose child cannot block on a full pipe.
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    timer.cancel()
    timeoutLock.lock()
    let commandTimedOut = didTimeOut
    timeoutLock.unlock()
    if commandTimedOut {
        return (124, "Command timed out: \(executable)")
    }
    return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
}
