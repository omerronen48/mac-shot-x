import XCTest
@testable import MacShotCore

final class HistoryStoreTests: XCTestCase {
    var dir: URL!
    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: dir) }

    private func writePNG(_ name: String, modified: Date) throws -> URL {
        let url = dir.appendingPathComponent(name)
        try Data([0x89, 0x50]).write(to: url)   // stub bytes; store lists by name/extension
        try FileManager.default.setAttributes([.modificationDate: modified], ofItemAtPath: url.path)
        return url
    }
    func testListsPNGsNewestFirst() throws {
        _ = try writePNG("old.png", modified: Date(timeIntervalSince1970: 100))
        _ = try writePNG("new.png", modified: Date(timeIntervalSince1970: 200))
        _ = try writePNG("notes.txt", modified: Date(timeIntervalSince1970: 300))  // ignored
        let store = HistoryStore(directory: dir, pins: PinStore(store: InMemoryKVStore()))
        XCTAssertEqual(store.entries().map(\.filename), ["new.png", "old.png"])
    }
    func testPinnedSurfacedToTop() throws {
        _ = try writePNG("a.png", modified: Date(timeIntervalSince1970: 300))
        let b = try writePNG("b.png", modified: Date(timeIntervalSince1970: 100))
        let pins = PinStore(store: InMemoryKVStore())
        let store = HistoryStore(directory: dir, pins: pins)
        store.pin(HistoryEntry(url: b, filename: "b.png",
                               captureDate: Date(timeIntervalSince1970: 100), isPinned: false))
        let e = store.entries()
        XCTAssertEqual(e.map(\.filename), ["b.png", "a.png"])   // pinned b first despite older
        XCTAssertTrue(e.first!.isPinned)
    }
    func testDeleteRemovesFile() throws {
        let a = try writePNG("a.png", modified: Date(timeIntervalSince1970: 1))
        let store = HistoryStore(directory: dir, pins: PinStore(store: InMemoryKVStore()))
        try store.delete(store.entries().first!)
        XCTAssertFalse(FileManager.default.fileExists(atPath: a.path))
        XCTAssertTrue(store.entries().isEmpty)
    }
}
