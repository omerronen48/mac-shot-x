import Foundation
import CoreGraphics

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
    let store: KeyValueStore
    public init(store: KeyValueStore) { self.store = store }

    private func s(_ k: String, _ def: String) -> String { store.string(forKey: k) ?? def }
    private func b(_ k: String, _ def: Bool) -> Bool { (store.object(forKey: k) as? Bool) ?? def }
    private func d(_ k: String, _ def: Double) -> Double { (store.object(forKey: k) as? Double) ?? def }

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

    public var captureDelaySeconds: Int {
        get { (store.object(forKey: "captureDelaySeconds") as? Int) ?? 0 }
        nonmutating set { store.set(newValue, forKey: "captureDelaySeconds") }
    }
    public var captureCursor: Bool {
        get { b("captureCursor", false) }
        nonmutating set { store.set(newValue, forKey: "captureCursor") }
    }
    public var downscaleRetina: Bool {
        get { b("downscaleRetina", false) }
        nonmutating set { store.set(newValue, forKey: "downscaleRetina") }
    }
    public var lastAreaRect: CGRect? {
        get {
            guard let a = store.object(forKey: "lastAreaRect") as? [Double], a.count == 4 else { return nil }
            return CGRect(x: a[0], y: a[1], width: a[2], height: a[3])
        }
        nonmutating set {
            if let r = newValue { store.set([Double(r.minX), Double(r.minY), Double(r.width), Double(r.height)], forKey: "lastAreaRect") }
            else { store.set(nil, forKey: "lastAreaRect") }
        }
    }
    public var lastAreaHotkey: String {
        get { store.string(forKey: "hotkey.lastArea") ?? "" }
        nonmutating set { store.set(newValue, forKey: "hotkey.lastArea") }
    }
    public var loupeSize: Double {
        get { d("loupeSize", 120) }
        nonmutating set { store.set(newValue, forKey: "loupeSize") }
    }
    public var loupeMagnification: Double {
        get { d("loupeMagnification", 8) }
        nonmutating set { store.set(newValue, forKey: "loupeMagnification") }
    }
    public var loupeOutlineEnabled: Bool {
        get { b("loupeOutlineEnabled", true) }
        nonmutating set { store.set(newValue, forKey: "loupeOutlineEnabled") }
    }
    public var loupeOutlineColor: RGBAColor {
        get {
            guard let a = store.object(forKey: "loupeOutlineColor") as? [Double], a.count == 4 else { return .white }
            return RGBAColor(r: a[0], g: a[1], b: a[2], a: a[3])
        }
        nonmutating set { store.set([newValue.r, newValue.g, newValue.b, newValue.a], forKey: "loupeOutlineColor") }
    }
    public var menuBarIconSymbol: String { get { s("menuBarIconSymbol", "camera.viewfinder") } nonmutating set { store.set(newValue, forKey: "menuBarIconSymbol") } }
    public var hideMenuBarIcon: Bool { get { b("hideMenuBarIcon", false) } nonmutating set { store.set(newValue, forKey: "hideMenuBarIcon") } }
    public var preferencesHotkey: String { get { s("preferencesHotkey", "⌃⌘⇧,") } nonmutating set { store.set(newValue, forKey: "preferencesHotkey") } }
    public var menuOrder: MenuOrder {
        get {
            guard let raw = store.string(forKey: "menuOrder"), let d = raw.data(using: .utf8),
                  let o = try? JSONDecoder().decode(MenuOrder.self, from: d) else { return .default }
            return o.normalized()
        }
        nonmutating set {
            if let d = try? JSONEncoder().encode(newValue.normalized()), let str = String(data: d, encoding: .utf8) {
                store.set(str, forKey: "menuOrder")
            }
        }
    }
}
