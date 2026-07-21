import Foundation

/// User presets persisted as JSON in KeyValueStore, merged with built-ins on read.
public struct PresetStore {
    private let store: KeyValueStore
    private let key = "beautifyPresets"
    public init(store: KeyValueStore) { self.store = store }

    private func userPresets() -> [BeautifyPreset] {
        guard let s = store.string(forKey: key),
              let data = s.data(using: .utf8),
              let list = try? JSONDecoder().decode([BeautifyPreset].self, from: data)
        else { return [] }
        return list
    }

    private func persist(_ list: [BeautifyPreset]) {
        guard let data = try? JSONEncoder().encode(list),
              let s = String(data: data, encoding: .utf8)
        else { return }
        store.set(s, forKey: key)
    }

    public func presets() -> [BeautifyPreset] {
        let user = userPresets()
        let userNames = Set(user.map(\.name))
        return BeautifyStyle.builtins.filter { !userNames.contains($0.name) } + user
    }

    public func save(_ preset: BeautifyPreset) {
        var list = userPresets().filter { $0.name != preset.name }
        list.append(preset)
        persist(list)
    }

    public func delete(name: String) {
        persist(userPresets().filter { $0.name != name })
    }
}
