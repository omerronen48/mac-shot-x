import XCTest
import CoreGraphics
@testable import MacShotCore

final class OCRTextAssemblerTests: XCTestCase {
    func obs(_ t: String, x: CGFloat, y: CGFloat, w: CGFloat = 40, h: CGFloat = 10) -> OCRObservation {
        OCRObservation(text: t, boundingBox: CGRect(x: x, y: y, width: w, height: h), confidence: 1)
    }
    func testEmptyIsEmptyString() {
        XCTAssertEqual(OCRTextAssembler.assemble([]), "")
    }
    func testSingleObservation() {
        XCTAssertEqual(OCRTextAssembler.assemble([obs("hello", x: 0, y: 0)]), "hello")
    }
    func testMultiLineTopToBottom() {
        // y is bottom-left origin: top line has the LARGER y
        let input = [obs("second", x: 0, y: 0), obs("first", x: 0, y: 100)]
        XCTAssertEqual(OCRTextAssembler.assemble(input), "first\nsecond")
    }
    func testTwoColumnsLeftThenRight() {
        // Left column x≈0, right column x≈500; each has two lines.
        let input = [
            obs("L1", x: 0,   y: 100), obs("L2", x: 0,   y: 0),
            obs("R1", x: 500, y: 100), obs("R2", x: 500, y: 0),
        ]
        XCTAssertEqual(OCRTextAssembler.assemble(input), "L1\nL2\nR1\nR2")
    }
}
