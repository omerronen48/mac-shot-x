import XCTest
@testable import MacShotCore

final class PreferencesM10Tests: XCTestCase {
    func testDefaults() {
        let p = Preferences(store: InMemoryKVStore())
        XCTAssertEqual(p.menuBarIconSymbol, "camera.viewfinder")
        XCTAssertFalse(p.hideMenuBarIcon)
        XCTAssertEqual(p.preferencesHotkey, "⌃⌘⇧,")
        XCTAssertEqual(p.menuOrder, .default)
    }
    func testRoundtrip() {
        let store = InMemoryKVStore()
        let p = Preferences(store: store)
        p.menuBarIconSymbol = "bolt.fill"; p.hideMenuBarIcon = true
        p.menuOrder = MenuOrder(items: [.ocr, .area, .window, .fullscreen, .lastArea])
        let q = Preferences(store: store)
        XCTAssertEqual(q.menuBarIconSymbol, "bolt.fill")
        XCTAssertTrue(q.hideMenuBarIcon)
        XCTAssertEqual(q.menuOrder.items.first, .ocr)
    }
}
