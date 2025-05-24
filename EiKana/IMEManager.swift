import Foundation
import Carbon

final class IMEManager {
    private static func callback(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent,
        refcon: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>? {
        let imeManager = Unmanaged<IMEManager>.fromOpaque(refcon!).takeUnretainedValue()
        return nil
    }

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
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                return IMEManager.callback(proxy: proxy, type: type, event: event, refcon: refcon)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
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
