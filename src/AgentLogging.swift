import Foundation

let debugLoggingEnabled = false

func logAgent(_ message: String) {
    print("[CmdTabUltra] \(message)")
}

func debugLogAgent(_ message: @autoclosure () -> String) {
    if debugLoggingEnabled {
        logAgent(message())
    }
}
