import XCTest
@testable import MacShotCore

final class HotkeySpecCommaTests: XCTestCase {
    func testCommaHotkeyParses() throws {
        let spec = try HotkeySpec(string: "⌃⌘⇧,")
        XCTAssertEqual(spec.keyCode, UInt32(43))   // Carbon kVK_ANSI_Comma
    }
}
