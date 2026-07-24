import XCTest
import CoreGraphics
@testable import MacShotCore

final class PreferencesM7Tests: XCTestCase {
    func testDefaults() {
        let p = Preferences(store: InMemoryKVStore())
        XCTAssertEqual(p.captureDelaySeconds, 0)
        XCTAssertFalse(p.captureCursor)
        XCTAssertFalse(p.downscaleRetina)
        XCTAssertNil(p.lastAreaRect)
        XCTAssertEqual(p.loupeSize, 120, accuracy: 0.001)
        XCTAssertEqual(p.loupeMagnification, 8, accuracy: 0.001)
        XCTAssertTrue(p.loupeOutlineEnabled)
        XCTAssertEqual(p.loupeOutlineColor, .white)
    }
    func testRoundtrip() {
        let store = InMemoryKVStore()
        let p = Preferences(store: store)
        p.captureDelaySeconds = 5
        p.captureCursor = true
        p.downscaleRetina = true
        p.lastAreaRect = CGRect(x: 10, y: 20, width: 300, height: 400)
        p.loupeMagnification = 6
        let r = Preferences(store: store)
        XCTAssertEqual(r.captureDelaySeconds, 5)
        XCTAssertTrue(r.captureCursor)
        XCTAssertTrue(r.downscaleRetina)
        XCTAssertEqual(r.lastAreaRect, CGRect(x: 10, y: 20, width: 300, height: 400))
        XCTAssertEqual(r.loupeMagnification, 6, accuracy: 0.001)
    }
}
