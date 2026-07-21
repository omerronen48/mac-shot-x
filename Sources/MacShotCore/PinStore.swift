import Foundation

/// Pinned screenshot paths persisted as a [String] in the KeyValueStore. No DB.
public struct PinStore {
    private let store: KeyValueStore
    private let key = "pinnedPaths"
    public init(store: KeyValueStore) { self.store = store }

    public func pins() -> Set<String> {
        Set((store.object(forKey: key) as? [String]) ?? [])
    }
    public func add(_ path: String) {
        var s = pins(); s.insert(path); store.set(Array(s).sorted(), forKey: key)
    }
    public func remove(_ path: String) {
        var s = pins(); s.remove(path); store.set(Array(s).sorted(), forKey: key)
    }
}
