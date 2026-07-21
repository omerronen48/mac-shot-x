import XCTest
@testable import MacShotCore

final class HotkeySpecTests: XCTestCase {
    func testParseAndSerializeSymmetry() throws {
        let spec = try HotkeySpec(string: "⌘⇧2")
        XCTAssertTrue(spec.modifiers.contains(.command))
        XCTAssertTrue(spec.modifiers.contains(.shift))
        XCTAssertEqual(spec.description, "⌘⇧2")
    }
    func testControlCommandShift() throws {
        let spec = try HotkeySpec(string: "⌃⌘⇧3")
        XCTAssertEqual(spec.modifiers, [.control, .command, .shift])
        XCTAssertEqual(spec.keyLabel, "3")
    }
    func testRejectsModifierOnly() {
        XCTAssertThrowsError(try HotkeySpec(string: "⌘⇧"))
    }
    func testLetterKeyParses() throws {
        let spec = try HotkeySpec(string: "⌃⌘⇧O")
        XCTAssertEqual(spec.keyCode, 31) // kVK_ANSI_O
    }
    func testCarbonModifierMaskIsStable() throws {
        // cmdKey=256, shiftKey=512 (Carbon constants); mask is their OR.
        let spec = try HotkeySpec(string: "⌘⇧2")
        XCTAssertEqual(spec.carbonModifierMask, 256 | 512)
    }
}
