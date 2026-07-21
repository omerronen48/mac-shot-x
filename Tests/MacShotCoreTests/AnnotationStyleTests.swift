import XCTest
import CoreGraphics
@testable import MacShotCore

final class AnnotationStyleTests: XCTestCase {
    func testRGBAToCGColorComponents() throws {
        let c = RGBAColor(r: 1, g: 0, b: 0, a: 1)
        let cg = c.cgColor
        let red = try XCTUnwrap(cg.components.map { Double($0[0]) })
        XCTAssertEqual(red, 1, accuracy: 0.001)  // red
        XCTAssertEqual(Double(cg.alpha), 1, accuracy: 0.001)
    }
    func testDefaultStyleIsRedStroke3() {
        let s = AnnotationStyle.default
        XCTAssertEqual(s.strokeColor, RGBAColor(r: 1, g: 0.231, b: 0.188, a: 1))  // #FF3B30
        XCTAssertEqual(s.lineWidth, 3)
    }
    func testCodableRoundtrip() throws {
        let s = AnnotationStyle(strokeColor: .init(r: 0, g: 1, b: 0, a: 0.5),
                                fillColor: nil, lineWidth: 5, fontSize: 20)
        let back = try JSONDecoder().decode(AnnotationStyle.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(back, s)
    }
}
