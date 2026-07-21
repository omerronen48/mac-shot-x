import XCTest
@testable import MacShotCore

// NSEvent.ModifierFlags device-independent bits (kept as literals — no AppKit import in core tests).
private let CMD: UInt = 1 << 20, SHIFT: UInt = 1 << 17, OPT: UInt = 1 << 19, CTRL: UInt = 1 << 18

final class HotkeyRecorderTests: XCTestCase {
    func testMapsDigitWithCommandShift() {
        let spec = HotkeyRecorder.spec(fromKeyCode: 19, cocoaModifierRawValue: CMD | SHIFT)  // 19 = "2"
        XCTAssertEqual(spec?.description, "⌘⇧2")
    }
    func testMapsLetterWithControlCommandShift() {
        let spec = HotkeyRecorder.spec(fromKeyCode: 31, cocoaModifierRawValue: CTRL | CMD | SHIFT)  // 31 = "O"
        XCTAssertEqual(spec?.modifiers, [.control, .command, .shift])
        XCTAssertEqual(spec?.keyLabel, "O")
    }
    func testUnmappedKeyCodeReturnsNil() {
        XCTAssertNil(HotkeyRecorder.spec(fromKeyCode: 56, cocoaModifierRawValue: SHIFT))  // 56 = shift key itself
    }
    func testReservedBlocksSystemCombos() {
        let cmd3 = HotkeyRecorder.spec(fromKeyCode: 20, cocoaModifierRawValue: CMD | SHIFT)!  // 20 = "3"
        XCTAssertTrue(HotkeyRecorder.isReserved(cmd3))                                        // ⌘⇧3 = system
        let ctrlCmdShift2 = HotkeyRecorder.spec(fromKeyCode: 19, cocoaModifierRawValue: CTRL | CMD | SHIFT)!
        XCTAssertFalse(HotkeyRecorder.isReserved(ctrlCmdShift2))                              // ⌃⌘⇧2 = app default
    }
}
