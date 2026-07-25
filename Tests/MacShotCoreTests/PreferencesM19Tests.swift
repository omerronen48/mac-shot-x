import XCTest
@testable import MacShotCore

final class PreferencesM19Tests: XCTestCase {
    func testDefault() {
        let store = InMemoryKVStore()
        XCTAssertEqual(Preferences(store: store).recordAreaHotkey, "⌃⌘⇧V")
    }
    func testRoundtrip() {
        let store = InMemoryKVStore()
        Preferences(store: store).recordAreaHotkey = "⌥⌘R"
        XCTAssertEqual(Preferences(store: store).recordAreaHotkey, "⌥⌘R")
    }
}
