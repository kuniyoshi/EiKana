import Foundation
import Carbon

final class IMEManager {
    private var eventTap: CFMachPort?
    private let queue = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, nil, 0)
    
    init() {
        setupEventTap()
    }
    
    deinit {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), queue, .commonModes)
        if let eventTap = eventTap {
            CFMachPortInvalidate(eventTap)
        }
    }
    
    private func setupEventTap() {
        let mask = (1 << CGEventType.keyDown.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { (_, event, _, _) -> Unmanaged<CGEvent>? in
                guard let event = event else { return nil }
                
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.getIntegerValueField(.keyboardEventFlags)
                
                // Check for left command key (55) and right command key (54)
                if keyCode == 55 && (flags & (1 << 24)) != 0 { // Left command key
                    self.switchToEisuMode()
                    return nil
                } else if keyCode == 54 && (flags & (1 << 24)) != 0 { // Right command key
                    self.switchToKanaMode()
                    return nil
                }
                
                return nil
            },
            userInfo: nil
        )
        
        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }
    
    private func switchToEisuMode() {
        let event = CGEvent(source: nil)
        event?.setIntegerValueField(.keyboardEventKeycode, value: 0x30) // 0x30 is the key code for switching to eisu mode
        event?.post(tap: .cghidEventTap)
    }
    
    private func switchToKanaMode() {
        let event = CGEvent(source: nil)
        event?.setIntegerValueField(.keyboardEventKeycode, value: 0x31) // 0x31 is the key code for switching to kana mode
        event?.post(tap: .cghidEventTap)
    }
}
