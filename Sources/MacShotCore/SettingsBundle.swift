import Foundation

/// Export/import of user settings as flat JSON. Operates over the KeyValueStore for a fixed
/// allow-list of keys; excludes screenshot history and any secret keys.
public enum SettingsBundle {
    public static let exportableKeys: [String] = [
        "filenameFormat", "saveDirectoryPath", "copyToClipboard", "saveToFile",
        "hotkey.area", "hotkey.window", "hotkey.fullscreen", "hotkey.ocr", "hotkey.lastArea",
        "captureDelaySeconds", "captureCursor", "downscaleRetina",
        "loupeSize", "loupeMagnification", "loupeOutlineEnabled", "loupeOutlineColor",
        "menuBarIconSymbol", "hideMenuBarIcon", "preferencesHotkey", "menuOrder",
    ]
    public static func export(from store: KeyValueStore) -> Data {
        var dict: [String: Any] = [:]
        for k in exportableKeys where store.object(forKey: k) != nil { dict[k] = store.object(forKey: k) }
        return (try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])) ?? Data("{}".utf8)
    }
    public static func load(_ data: Data, into store: KeyValueStore) {
        guard let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return }
        for k in exportableKeys { if let v = dict[k] { store.set(v, forKey: k) } }
    }
}
