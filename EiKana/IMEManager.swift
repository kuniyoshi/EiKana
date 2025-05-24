import Foundation
import Carbon
import Carbon.HIToolbox

final class IMEManager {
    private static func callback(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent,
        refcon: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>? {
        let imeManager = Unmanaged<IMEManager>.fromOpaque(refcon!).takeUnretainedValue()
        // Only interested in keyDown events
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            print(keyCode)
            let flags = event.flags
            // Left Command key code is 0x37 on macOS
            let leftCommandKeyCode: CGKeyCode = 0x37
            // Detect if only the Command flag is set (no other modifiers)
            if keyCode == leftCommandKeyCode && flags == .maskCommand {
                // Handle the single Command key press
                imeManager.switchToEisuMode() // or whichever method you want to call
                return nil // swallow the event if desired
            }
            // Right Command key code is 0x36 on macOS
            let rightCommandKeyCode: CGKeyCode = 0x36
            if keyCode == rightCommandKeyCode && flags == .maskCommand {
                // Handle the single right Command key press
                imeManager.switchToKanaMode()
                return nil // swallow the event if desired
            }
        }
        // Pass through all other events
        return Unmanaged.passUnretained(event)
    }

    private var eventTap: CFMachPort?
//    private let queue = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, nil, 0)

    init() {
        setupEventTap()
    }

    deinit {
//        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), queue, .commonModes)
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
