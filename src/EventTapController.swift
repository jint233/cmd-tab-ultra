import ApplicationServices
import Cocoa

var eventTap: CFMachPort?
var eventTapRunLoopSource: CFRunLoopSource?
private var eventTapRetryInterval: TimeInterval = 2.0
private let eventTapMaxRetryInterval: TimeInterval = 60.0

let eventsOfInterest: CGEventMask =
    (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
    | (1 << CGEventType.tapDisabledByTimeout.rawValue)
    | (1 << CGEventType.tapDisabledByUserInput.rawValue)

private let commandKeyCodes: Set<Int64> = [54, 55]

func installEventTapWhenAvailable() {
    if let existingTap = eventTap, CFMachPortIsValid(existingTap) {
        CGEvent.tapEnable(tap: existingTap, enable: true)
        markAgentReady()
        return
    }

    guard
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventsOfInterest,
            callback: eventCallback,
            userInfo: nil
        )
    else {
        logAgent("Could not create event tap; retrying in \(Int(eventTapRetryInterval)) seconds")
        let delay = eventTapRetryInterval
        // Exponential backoff: 2s → 4s → 8s → … → 60s cap
        eventTapRetryInterval = min(eventTapRetryInterval * 2, eventTapMaxRetryInterval)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            installEventTapWhenAvailable()
        }
        return
    }

    // Invalidate old tap before replacing to prevent resource leak.
    if let oldTap = eventTap {
        CGEvent.tapEnable(tap: oldTap, enable: false)
        CFMachPortInvalidate(oldTap)
    }
    if let source = eventTapRunLoopSource {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
    }

    eventTap = tap
    eventTapRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    if let source = eventTapRunLoopSource {
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    }
    CGEvent.tapEnable(tap: tap, enable: true)
    eventTapRetryInterval = 2.0  // Reset backoff on success.
    markAgentReady()
    logAgent("Event tap created, run loop starting")
}

func markAgentReady() {
    let readyURL = URL(fileURLWithPath: agentReadyPath)
    try? FileManager.default.createDirectory(
        at: readyURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try? "\(getpid())\n".write(to: readyURL, atomically: true, encoding: .utf8)
}

let eventCallback: CGEventTapCallBack = { _, type, event, _ in
    switch type {
    case .tapDisabledByTimeout, .tapDisabledByUserInput:
        DispatchQueue.main.async {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
                logAgent("Event tap re-enabled after \(type)")
            } else {
                installEventTapWhenAvailable()
            }
        }
    case .keyDown:
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard keyCode == tabKeyCode, event.flags.contains(.maskCommand) else {
            return Unmanaged.passUnretained(event)
        }
        let flags = event.flags
        DispatchQueue.main.async {
            cmdTabSwitchState.handleTabKeyDown(keyCode: keyCode, flags: flags)
        }
    case .flagsChanged:
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard commandKeyCodes.contains(keyCode) else {
            return Unmanaged.passUnretained(event)
        }
        let flags = event.flags
        DispatchQueue.main.async {
            cmdTabSwitchState.handleFlagsChanged(flags: flags)
        }
    default:
        break
    }
    return Unmanaged.passUnretained(event)
}
