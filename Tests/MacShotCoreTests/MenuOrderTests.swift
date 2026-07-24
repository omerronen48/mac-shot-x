import XCTest
@testable import MacShotCore

final class MenuOrderTests: XCTestCase {
    func testDefaultHasEveryActionOnce() {
        let d = MenuOrder.default
        XCTAssertEqual(Set(d.items), Set(CaptureAction.allCases))
        XCTAssertEqual(d.items.count, CaptureAction.allCases.count)
    }
    func testMoveReorders() {
        var o = MenuOrder(items: [.area, .window, .fullscreen])
        o.move(from: 0, to: 2)
        XCTAssertEqual(o.items, [.window, .fullscreen, .area])
    }
    func testCodableRoundtrip() throws {
        let o = MenuOrder(items: [.ocr, .area, .lastArea, .window, .fullscreen])
        XCTAssertEqual(try JSONDecoder().decode(MenuOrder.self, from: JSONEncoder().encode(o)), o)
    }
    func testNormalizeFillsMissingAndDropsDupes() {
        let o = MenuOrder(items: [.area, .area]).normalized()
        XCTAssertEqual(Set(o.items), Set(CaptureAction.allCases))   // all present, no dupes
        XCTAssertEqual(o.items.first, .area)                         // preserves given order first
    }
}
