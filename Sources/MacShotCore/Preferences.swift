import Foundation

public protocol KeyValueStore: AnyObject {
    func string(forKey: String) -> String?
    func object(forKey: String) -> Any?
    func set(_ value: Any?, forKey: String)
}
extension UserDefaults: KeyValueStore {}

public final class InMemoryKVStore: KeyValueStore {
    private var d: [String: Any] = [:]
    public init() {}
    public func string(forKey k: String) -> String? { d[k] as? String }
    public func object(forKey k: String) -> Any? { d[k] }
    public func set(_ value: Any?, forKey k: String) { d[k] = value }
}

/// UserDefaults-backed preferences (roadmap: PNG files + UserDefaults, no DB).
public struct Preferences {
    private let store: KeyValueStore
    public init(store: KeyValueStore) { self.store = store }

    private func s(_ k: String, _ def: String) -> String { store.string(forKey: k) ?? def }
    private func b(_ k: String, _ def: Bool) -> Bool { (store.object(forKey: k) as? Bool) ?? def }

    public var filenameFormat: String {
        get { s("filenameFormat", "Screenshot {date} at {time}") }
        nonmutating set { store.set(newValue, forKey: "filenameFormat") }
    }
    public var saveDirectoryPath: String {
        get { s("saveDirectoryPath", (NSHomeDirectory() as NSString).appendingPathComponent("Pictures/MacShot")) }
        nonmutating set { store.set(newValue, forKey: "saveDirectoryPath") }
    }
    public var copyToClipboard: Bool {
        get { b("copyToClipboard", true) }
        nonmutating set { store.set(newValue, forKey: "copyToClipboard") }
    }
    public var saveToFile: Bool {
        get { b("saveToFile", true) }
        nonmutating set { store.set(newValue, forKey: "saveToFile") }
    }
    // Hotkeys stored as their symbol strings; parsed via HotkeySpec at registration.
    public var areaHotkey: String { get { s("hotkey.area", "⌘⇧2") } nonmutating set { store.set(newValue, forKey: "hotkey.area") } }
    public var windowHotkey: String { get { s("hotkey.window", "⌃⌘⇧2") } nonmutating set { store.set(newValue, forKey: "hotkey.window") } }
    public var fullscreenHotkey: String { get { s("hotkey.fullscreen", "⌃⌘⇧3") } nonmutating set { store.set(newValue, forKey: "hotkey.fullscreen") } }
    public var ocrHotkey: String { get { s("hotkey.ocr", "⌃⌘⇧O") } nonmutating set { store.set(newValue, forKey: "hotkey.ocr") } }
}
