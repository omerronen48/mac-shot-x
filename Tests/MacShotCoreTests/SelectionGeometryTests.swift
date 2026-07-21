import XCTest
import CoreGraphics
@testable import MacShotCore

final class SelectionGeometryTests: XCTestCase {
    func testRectFromDragNormalizesDirection() {
        let r = SelectionGeometry.rect(from: CGPoint(x: 100, y: 100), to: CGPoint(x: 40, y: 30))
        XCTAssertEqual(r, CGRect(x: 40, y: 30, width: 60, height: 70))
    }
    func testClampToBounds() {
        let bounds = CGRect(x: 0, y: 0, width: 200, height: 200)
        let r = SelectionGeometry.rect(from: CGPoint(x: -10, y: -10), to: CGPoint(x: 250, y: 100))
        XCTAssertEqual(SelectionGeometry.clamp(r, to: bounds), CGRect(x: 0, y: 0, width: 200, height: 110))
    }
    func testTooSmallIsNil() {
        XCTAssertNil(SelectionGeometry.validated(CGRect(x: 0, y: 0, width: 3, height: 3), minSide: 5))
        XCTAssertNotNil(SelectionGeometry.validated(CGRect(x: 0, y: 0, width: 10, height: 10), minSide: 5))
    }
}
