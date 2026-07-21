import Foundation

public struct HotkeyModifiers: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let command = HotkeyModifiers(rawValue: 1 << 0)
    public static let shift   = HotkeyModifiers(rawValue: 1 << 1)
    public static let option  = HotkeyModifiers(rawValue: 1 << 2)
    public static let control = HotkeyModifiers(rawValue: 1 << 3)
}

public struct HotkeySpec: Equatable, Sendable, CustomStringConvertible {
    public let modifiers: HotkeyModifiers
    public let keyLabel: String     // "2", "3", "A" ...
    public let keyCode: UInt32      // Carbon virtual keycode

    enum ParseError: Error { case noKey }

    // Symbol ↔ modifier
    private static let symbols: [(Character, HotkeyModifiers)] =
        [("⌃", .control), ("⌥", .option), ("⇧", .shift), ("⌘", .command)]
    // Minimal key label → Carbon virtual keycode map (extend as needed)
    static let keyCodes: [String: UInt32] = [
        "1":18,"2":19,"3":20,"4":21,"5":23,"6":22,"7":26,"8":28,"9":25,"0":29
    ]

    public init(string: String) throws {
        var mods: HotkeyModifiers = []
        var key = ""
        for ch in string {
            if let m = Self.symbols.first(where: { $0.0 == ch })?.1 { mods.insert(m) }
            else { key.append(ch) }
        }
        guard !key.isEmpty, let code = Self.keyCodes[key.uppercased()] ?? Self.keyCodes[key] else {
            throw ParseError.noKey
        }
        self.modifiers = mods; self.keyLabel = key; self.keyCode = code
    }

    public init(modifiers: HotkeyModifiers, keyLabel: String, keyCode: UInt32) {
        self.modifiers = modifiers; self.keyLabel = keyLabel; self.keyCode = keyCode
    }

    public var description: String {
        let order: [(HotkeyModifiers, String)] =
            [(.control,"⌃"),(.option,"⌥"),(.command,"⌘"),(.shift,"⇧")]
        return order.filter { modifiers.contains($0.0) }.map(\.1).joined() + keyLabel
    }

    /// Carbon `modifierFlags` mask (cmdKey=256, shiftKey=512, optionKey=2048, controlKey=4096).
    public var carbonModifierMask: UInt32 {
        var m: UInt32 = 0
        if modifiers.contains(.command) { m |= 256 }
        if modifiers.contains(.shift)   { m |= 512 }
        if modifiers.contains(.option)  { m |= 2048 }
        if modifiers.contains(.control) { m |= 4096 }
        return m
    }

    public static let defaults: [CaptureMode.Kind: HotkeySpec] = [:]
}

extension CaptureMode { public enum Kind: String, Sendable { case area, window, fullscreen } }
