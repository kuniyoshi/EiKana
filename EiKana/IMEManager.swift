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
    
    private var leftCommandKeyPressed = false
    private var rightCommandKeyPressed = false
    private var otherKeyPressed = false
    
    private func setupEventTap() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue | 1 << CGEventType.keyUp.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { [weak self] (_, event, _, _) -> Unmanaged<CGEvent>? in
                guard let self = self else { return Unmanaged.passRetained(event) }
                
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.getIntegerValueField(.keyboardEventFlags)
                let isKeyDown = event.type == .keyDown
                let isKeyUp = event.type == .keyUp
                
                if keyCode == 55 {
                    if isKeyDown {
                        self.leftCommandKeyPressed = true
                        self.otherKeyPressed = false
                    } else if isKeyUp && self.leftCommandKeyPressed && !self.otherKeyPressed {
                        self.leftCommandKeyPressed = false
                        self.switchToEisuMode()
                        return nil // Consume the event only when we switch modes
                    } else if isKeyUp {
                        self.leftCommandKeyPressed = false
                    }
                }
                // Right command key (54)
                else if keyCode == 54 {
                    if isKeyDown {
                        self.rightCommandKeyPressed = true
                        self.otherKeyPressed = false
                    } else if isKeyUp && self.rightCommandKeyPressed && !self.otherKeyPressed {
                        self.rightCommandKeyPressed = false
                        self.switchToKanaMode()
                        return nil // Consume the event only when we switch modes
                    } else if isKeyUp {
                        self.rightCommandKeyPressed = false
                    }
                }
                else if isKeyDown {
                    self.otherKeyPressed = true
                }
                
                return Unmanaged.passRetained(event)
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
