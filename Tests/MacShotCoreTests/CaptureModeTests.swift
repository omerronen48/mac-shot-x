import XCTest
@testable import MacShotCore

final class CaptureModeTests: XCTestCase {
    func testModeSlugsAreStableForFilenames() {
        XCTAssertEqual(CaptureMode.area(nil).slug, "area")
        XCTAssertEqual(CaptureMode.window(nil).slug, "window")
        XCTAssertEqual(CaptureMode.fullscreen(nil).slug, "fullscreen")
    }
    func testNeedsSelectionOverlay() {
        XCTAssertTrue(CaptureMode.area(nil).needsSelectionUI)
        XCTAssertTrue(CaptureMode.window(nil).needsSelectionUI)
        XCTAssertFalse(CaptureMode.fullscreen(nil).needsSelectionUI)
    }
}
