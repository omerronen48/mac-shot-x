import XCTest
import CoreGraphics
@testable import MacShotCore

final class PinGeometryTests: XCTestCase {
    func testClampOpacityBounds() {
        XCTAssertEqual(PinGeometry.clampOpacity(0.0), 0.2, accuracy: 0.001)
        XCTAssertEqual(PinGeometry.clampOpacity(0.5), 0.5, accuracy: 0.001)
        XCTAssertEqual(PinGeometry.clampOpacity(2.0), 1.0, accuracy: 0.001)
    }
    func testInitialFrameAspectFitAndCentered() {
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let f = PinGeometry.initialFrame(imageSize: CGSize(width: 4000, height: 2000), screen: screen, maxFraction: 0.5)
        XCTAssertEqual(f.width, 720, accuracy: 0.5)
        XCTAssertEqual(f.height, 360, accuracy: 0.5)
        XCTAssertEqual(f.midX, screen.midX, accuracy: 0.5)
        XCTAssertEqual(f.midY, screen.midY, accuracy: 0.5)
    }
    func testInitialFrameDoesNotUpscaleSmallImage() {
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let f = PinGeometry.initialFrame(imageSize: CGSize(width: 100, height: 50), screen: screen, maxFraction: 0.5)
        XCTAssertEqual(f.size, CGSize(width: 100, height: 50))
    }
}
