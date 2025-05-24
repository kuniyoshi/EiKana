import Foundation
import Carbon
import Carbon.HIToolbox
import CoreFoundation

private func postInputSourceChangedNotification() {
    let center = CFNotificationCenterGetDistributedCenter()
    CFNotificationCenterPostNotification(
        center,
        CFNotificationName("com.apple.inputSourceChanged" as CFString),
        nil, nil, true
    )
}

/// Simulate a hardware key press for the given virtual key code
private func simulateKeyPress(_ keyCode: CGKeyCode) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }
    // Key down
    let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
    down?.post(tap: .cghidEventTap)
    // Key up
    let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
    up?.post(tap: .cghidEventTap)
}

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
//    private let queue = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, nil, 0)

    init() {
        setupEventTap()
        printAllInputSourceIDs()
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
    func printAllInputSourceIDs() {
        guard let list = TISCreateInputSourceList(nil, false)?
                .takeRetainedValue() as? [TISInputSource] else {
            print("Could not retrieve input source list")
            return
        }

        for source in list {
            // Helper closure to safely extract a CFString property
            func string(for key: CFString) -> String {
                guard let rawPtr = TISGetInputSourceProperty(source, key) else {
                    return "-"
                }

                // TISGetInputSourceProperty returns an UnsafeMutableRawPointer; convert to Unmanaged
                let unmanaged = Unmanaged<CFTypeRef>.fromOpaque(rawPtr)
                let cfValue = unmanaged.takeUnretainedValue()

                guard CFGetTypeID(cfValue) == CFStringGetTypeID(),
                      let str = cfValue as? String else {
                    return "-"
                }
                return str
            }

            let idStr   = string(for: kTISPropertyInputSourceID)
            let modeStr = string(for: kTISPropertyInputModeID)
            let nameStr = string(for: kTISPropertyLocalizedName)

            print("ID: \(idStr)\tMode: \(modeStr)\tName: \(nameStr)")
        }
    }
}
