import XCTest
@testable import MacShotCore

final class PreferencesTests: XCTestCase {
    func testDefaultsWhenStoreEmpty() {
        let prefs = Preferences(store: InMemoryKVStore())
        XCTAssertEqual(prefs.filenameFormat, "Screenshot {date} at {time}")
        XCTAssertTrue(prefs.copyToClipboard)
        XCTAssertTrue(prefs.saveToFile)
    }
    func testRoundtrip() {
        let store = InMemoryKVStore()
        var prefs = Preferences(store: store)
        prefs.filenameFormat = "X {mode}"
        prefs.saveDirectoryPath = "/tmp/shots"
        prefs.copyToClipboard = false
        let reloaded = Preferences(store: store)
        XCTAssertEqual(reloaded.saveDirectoryPath, "/tmp/shots")
        XCTAssertFalse(reloaded.copyToClipboard)
    }
}
