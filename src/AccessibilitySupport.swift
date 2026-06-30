import ApplicationServices
import Cocoa
import Foundation

let axMessagingTimeout: Float = 0.25

func appAccessibilityElement(for app: NSRunningApplication) -> AXUIElement {
    let axApp = AXUIElementCreateApplication(app.processIdentifier)
    AXUIElementSetMessagingTimeout(axApp, axMessagingTimeout)
    return axApp
}

func axBoolAttribute(_ attribute: CFString, of element: AXUIElement) -> Bool {
    var valueRef: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute, &valueRef) == .success,
        let value = valueRef
    else {
        return false
    }

    if let bool = value as? Bool {
        return bool
    }

    if let number = value as? NSNumber {
        return number.boolValue
    }

    return false
}

func requireAccessibility() {
    let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
    var waitCount = 0
    while !AXIsProcessTrusted() {
        if waitCount == 0 || waitCount % 10 == 0 {
            logAgent("waiting for Accessibility permission")
        }
        waitCount += 1
        _ = AXIsProcessTrustedWithOptions(opts)
        // Use RunLoop instead of Thread.sleep so the main thread remains
        // responsive to signals and dispatched blocks while waiting.
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))
    }
    logAgent("Accessibility granted; continuing")
}

func resetAccessibilityPermission() {
    _ = runCommand("/usr/bin/tccutil", ["reset", "Accessibility", serviceLabel])
}
