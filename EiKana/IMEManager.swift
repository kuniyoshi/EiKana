import Foundation
import Carbon
import CoreFoundation

/**
 Manages input method switching by intercepting Command key events.

 - Installs an event tap to listen for keyDown and flagsChanged events.
 - On left Command key release, switches to Eisu mode.
 - On right Command key release, switches to Kana mode.
 */
final class IMEManager {
    private var runLoopSource: CFRunLoopSource?

    private static func callback(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent,
        refcon: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>? {
        let imeManager = Unmanaged<IMEManager>.fromOpaque(refcon!).takeUnretainedValue()
        if type == .flagsChanged {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            print("flags", keyCode)
            let flags = event.flags

            // Left Command key code is 0x37 on macOS
            let leftCommandKeyCode: CGKeyCode = 0x37
            if keyCode == leftCommandKeyCode {
                if flags.contains(.maskCommand) {
                    // press - do nothing
                } else {
                    // release - switch to Eisu
                    imeManager.switchToEisuMode()
                }
                return Unmanaged.passUnretained(event)
            }

            // Right Command key code is 0x36 on macOS
            let rightCommandKeyCode: CGKeyCode = 0x36
            if keyCode == rightCommandKeyCode {
                if flags.contains(.maskCommand) {
                    // press - do nothing
                } else {
                    // release - switch to Kana
                    imeManager.switchToKanaMode()
                }
                return Unmanaged.passUnretained(event)
            }
        }
        // Only interested in keyDown events
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            print("key", keyCode)
            return Unmanaged.passUnretained(event)
        }
        // Pass through all other events
        return Unmanaged.passUnretained(event)
    }

    private var eventTap: CFMachPort?

    init() {
        setupEventTap()
    }

    deinit {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        if let eventTap = eventTap {
            CFMachPortInvalidate(eventTap)
        }
    }

    private func setupEventTap() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue) | CGEventMask(1 << CGEventType.flagsChanged.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                return IMEManager.callback(proxy: proxy, type: type, event: event, refcon: refcon)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        if let eventTap = eventTap {
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            if let runLoopSource = runLoopSource {
                CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }

    private func switchToEisuMode() {
        print("set eisu mode")
        // Toggle IME via virtual key event (same as `osascript -e '... key code 102'`)
        simulateKeyPress(102)
    }

    private func switchToKanaMode() {
        print("set kana mode")
        // Toggle IME via virtual key event (same as `osascript -e '... key code 102'`)
        simulateKeyPress(104)
    }

    /// Simulate a hardware key press for the given virtual key code
    private func simulateKeyPress(_ keyCode: CGKeyCode) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        // Key down
        CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)?
            .post(tap: .cghidEventTap)
        // Key up
        CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)?
            .post(tap: .cghidEventTap)
    }
}
