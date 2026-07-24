import XCTest
import CoreGraphics
@testable import MacShotCore

final class LoupeGeometryTests: XCTestCase {
    func testSampleRectCenteredAndScaled() {
        let r = LoupeGeometry.sampleRect(cursor: CGPoint(x: 100, y: 100), magnification: 8, loupeSize: 120)
        XCTAssertEqual(r, CGRect(x: 92.5, y: 92.5, width: 15, height: 15))
    }
    func testLoupeRectStaysInsideBoundsNearCorner() {
        let bounds = CGRect(x: 0, y: 0, width: 200, height: 200)
        let r = LoupeGeometry.loupeRect(cursor: CGPoint(x: 195, y: 195), loupeSize: 120, in: bounds)
        XCTAssertTrue(bounds.contains(r), "loupe \(r) must stay within \(bounds)")
    }
    func testLoupeRectOffsetFromCursorWhenRoomy() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        let r = LoupeGeometry.loupeRect(cursor: CGPoint(x: 100, y: 100), loupeSize: 120, in: bounds)
        XCTAssertGreaterThan(r.minX, 100)
        XCTAssertEqual(r.size, CGSize(width: 120, height: 120))
    }
}
