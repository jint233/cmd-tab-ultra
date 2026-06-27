import ApplicationServices
import Cocoa

var eventTap: CFMachPort?
var eventTapRunLoopSource: CFRunLoopSource?

let eventsOfInterest: CGEventMask =
    (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
    | (1 << CGEventType.tapDisabledByTimeout.rawValue)
    | (1 << CGEventType.tapDisabledByUserInput.rawValue)

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
            options: .defaultTap,
            eventsOfInterest: eventsOfInterest,
            callback: eventCallback,
            userInfo: nil
        )
    else {
        logAgent("Could not create event tap; retrying in 2 seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            installEventTapWhenAvailable()
        }
        return
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
        let flags = event.flags
        DispatchQueue.main.async {
            cmdTabSwitchState.handleTabKeyDown(keyCode: keyCode, flags: flags)
        }
    case .flagsChanged:
        let flags = event.flags
        DispatchQueue.main.async {
            cmdTabSwitchState.handleFlagsChanged(flags: flags)
        }
    default:
        break
    }
    return Unmanaged.passUnretained(event)
}
