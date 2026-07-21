import Foundation

/// Converts a recorded key event (Carbon keyCode + Cocoa modifier bits) into a
/// HotkeySpec, and flags macOS-reserved screenshot combos. Pure → headless-testable.
public enum HotkeyRecorder {
    // NSEvent.ModifierFlags device-independent bits
    private static let cmdBit: UInt = 1 << 20
    private static let shiftBit: UInt = 1 << 17
    private static let optBit: UInt = 1 << 19
    private static let ctrlBit: UInt = 1 << 18

    public static func spec(fromKeyCode keyCode: UInt32, cocoaModifierRawValue raw: UInt) -> HotkeySpec? {
        guard let label = HotkeySpec.keyCodes.first(where: { $0.value == keyCode })?.key else { return nil }
        var mods: HotkeyModifiers = []
        if raw & cmdBit != 0 { mods.insert(.command) }
        if raw & shiftBit != 0 { mods.insert(.shift) }
        if raw & optBit != 0 { mods.insert(.option) }
        if raw & ctrlBit != 0 { mods.insert(.control) }
        return HotkeySpec(modifiers: mods, keyLabel: label, keyCode: keyCode)
    }

    /// macOS system screenshot shortcuts: ⌘⇧3/4/5/6.
    public static func isReserved(_ spec: HotkeySpec) -> Bool {
        spec.modifiers == [.command, .shift] && ["3", "4", "5", "6"].contains(spec.keyLabel)
    }
}
