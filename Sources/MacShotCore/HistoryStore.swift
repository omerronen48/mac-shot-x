import Foundation

/// History = the save-dir folder of PNGs (no DB). Pinned entries surface first.
public struct HistoryStore {
    private let directory: URL
    private let pins: PinStore
    public init(directory: URL, pins: PinStore) { self.directory = directory; self.pins = pins }

    public func entries() -> [HistoryEntry] {
        let fm = FileManager.default
        let pinned = pins.pins()
        let urls = (try? fm.contentsOfDirectory(at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles])) ?? []
        let items = urls.filter { $0.pathExtension.lowercased() == "png" }.map { url -> HistoryEntry in
            let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            // ponytail: resolve symlinks so /var/… and /private/var/… paths compare equal (macOS tmp dir)
            let resolvedPath = url.resolvingSymlinksInPath().path
            return HistoryEntry(url: url, filename: url.lastPathComponent,
                                captureDate: date, isPinned: pinned.contains(resolvedPath))
        }
        // pinned first, each group newest-first
        return items.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned && !$1.isPinned }
            return $0.captureDate > $1.captureDate
        }
    }
    public func delete(_ entry: HistoryEntry) throws {
        try FileManager.default.removeItem(at: entry.url)
        pins.remove(entry.url.resolvingSymlinksInPath().path)
    }
    public func pin(_ entry: HistoryEntry) { pins.add(entry.url.resolvingSymlinksInPath().path) }
    public func unpin(_ entry: HistoryEntry) { pins.remove(entry.url.resolvingSymlinksInPath().path) }
}
