import Foundation
import Carbon
import CoreFoundation
import SwiftUI
/**
 Manages input method switching by intercepting Command key events.
 - Installs an event tap to listen for keyDown and flagsChanged events.
 - On left modifier key release, switches to Eisu mode.
 - On right modifier key release, switches to Kana mode.
 */
final class IMEManager {
    @AppStorage("modifierKeyType") private var modifierKeyType: String = "control"
    private var isLeftModifierKeyDown = false
    private var leftKeyUsedAsModifier = false
    private var isRightModifierKeyDown = false
    private var rightKeyUsedAsModifier = false
    // 長押し判定用
    private let modifierLongPressThreshold: CFTimeInterval = 0.2
    private var leftModifierDownTime: CFTimeInterval = 0
    private var rightModifierDownTime: CFTimeInterval = 0
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
            let useControl = imeManager.modifierKeyType == "control"
            let leftModifierKeyCode: CGKeyCode = useControl ? 0x3B : 0x37
            let leftModifierFlag: CGEventFlags = useControl ? .maskControl : .maskCommand
            let rightModifierKeyCode: CGKeyCode = useControl ? 0x3E : 0x36
            let rightModifierFlag: CGEventFlags = useControl ? .maskControl : .maskCommand
            if keyCode == leftModifierKeyCode {
                if flags.contains(leftModifierFlag) {
                    // left modifier key pressed
                    imeManager.isLeftModifierKeyDown = true
                    imeManager.leftKeyUsedAsModifier = false
                    imeManager.leftModifierDownTime = CFAbsoluteTimeGetCurrent()
                } else {
                    // left modifier key released
                    // 長押しの場合は修飾キー操作とみなす
                    let elapsed = CFAbsoluteTimeGetCurrent() - imeManager.leftModifierDownTime
                    if imeManager.isLeftModifierKeyDown && !imeManager.leftKeyUsedAsModifier && elapsed <= imeManager.modifierLongPressThreshold {
                        imeManager.switchToEisuMode()
                    }
                    imeManager.isLeftModifierKeyDown = false
                }
                return Unmanaged.passUnretained(event)
            }
            // Right modifier key handling (configurable)
            if keyCode == rightModifierKeyCode {
                if flags.contains(rightModifierFlag) {
                    // right modifier pressed
                    imeManager.isRightModifierKeyDown = true
                    imeManager.rightKeyUsedAsModifier = false
                    imeManager.rightModifierDownTime = CFAbsoluteTimeGetCurrent()
                } else {
                    // right modifier released
                    let elapsed = CFAbsoluteTimeGetCurrent() - imeManager.rightModifierDownTime
                    if imeManager.isRightModifierKeyDown && !imeManager.rightKeyUsedAsModifier && elapsed <= imeManager.modifierLongPressThreshold {
                        imeManager.switchToKanaMode()
                    }
                    imeManager.isRightModifierKeyDown = false
                }
                return Unmanaged.passUnretained(event)
            }
        }
        // Only interested in keyDown events
        if type == .keyDown {
            // If any other key is pressed while control or command is down, mark as modifier usage
            if imeManager.isLeftModifierKeyDown {
                imeManager.leftKeyUsedAsModifier = true
            }
            if imeManager.isRightModifierKeyDown {
                imeManager.rightKeyUsedAsModifier = true
            }
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            print("key", keyCode)
            return Unmanaged.passUnretained(event)
        }
        // Pass through all other events
        return Unmanaged.passUnretained(event)
    }
    private var runLoopSource: CFRunLoopSource?
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
        print("Set eisu mode")
        // Set to eisu
        simulateKeyPress(102)
    }
    private func switchToKanaMode() {
        print("Set kana mode")
        // Set to kana
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
