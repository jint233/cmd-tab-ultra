import ApplicationServices
import Foundation

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
        Thread.sleep(forTimeInterval: 1.0)
    }
    logAgent("Accessibility granted; continuing")
}
