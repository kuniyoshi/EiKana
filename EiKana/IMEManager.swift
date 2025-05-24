import Foundation
import Carbon
import Carbon.HIToolbox
import CoreFoundation


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
            if keyCode == leftCommandKeyCode && flags.contains(.maskCommand) {
                imeManager.switchToEisuMode()
                return nil
            }

            // Right Command key code is 0x36 on macOS
            let rightCommandKeyCode: CGKeyCode = 0x36
            if keyCode == rightCommandKeyCode && flags.contains(.maskCommand) {
                imeManager.switchToKanaMode()
                return nil
            }
        }
        // Only interested in keyDown events
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            print("key", keyCode)
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
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            if let runLoopSource = runLoopSource {
                CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }

    private func switchToEisuMode() {
        print("set eisu mode")


        if let sourceList = TISCreateInputSourceList(
            [
                kTISPropertyInputSourceType: kTISTypeKeyboardInputMode,
                kTISPropertyInputSourceID: "com.apple.inputmethod.Kotoeri.KanaTyping.Roman" as CFString
            ] as CFDictionary,
            false
        )?.takeRetainedValue() as? [TISInputSource],
           let source = sourceList.first {

            let isEnabled = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled) as? Bool ?? false
            print("ABC source isEnabled:", isEnabled)

            TISSelectInputSource(source)
        } else {
            print("ABC input source not found")
        }
    }

    private func switchToKanaMode() {
        print("set kana mode")
        if let sourceList = TISCreateInputSourceList(
            [
                kTISPropertyInputSourceType: kTISTypeKeyboardInputMode,
                kTISPropertyInputSourceID: "com.apple.inputmethod.Kotoeri.KanaTyping.Japanese" as CFString
            ] as CFDictionary,
            false
        )?.takeRetainedValue() as? [TISInputSource],
           let source = sourceList.first {

            let isEnabled = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled) as? Bool ?? false
            print("Kana source isEnabled:", isEnabled)

            TISSelectInputSource(source)
        } else {
            print("Kana input source not found")
        }
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
