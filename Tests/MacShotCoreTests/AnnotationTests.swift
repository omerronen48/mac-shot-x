import XCTest
import CoreGraphics
@testable import MacShotCore

final class AnnotationTests: XCTestCase {
    func testRectBoundingBox() {
        let a = Annotation(kind: .rectangle(CGRect(x: 10, y: 20, width: 30, height: 40)), style: .default)
        XCTAssertEqual(a.boundingBox, CGRect(x: 10, y: 20, width: 30, height: 40))
    }
    func testArrowBoundingBoxSpansEndpoints() {
        let a = Annotation(kind: .arrow(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 10, y: 5)), style: .default)
        XCTAssertEqual(a.boundingBox, CGRect(x: 0, y: 0, width: 10, height: 5))
    }
    func testContainsUsesBoundingBox() {
        let a = Annotation(kind: .ellipse(CGRect(x: 0, y: 0, width: 100, height: 100)), style: .default)
        XCTAssertTrue(a.contains(CGPoint(x: 50, y: 50)))
        XCTAssertFalse(a.contains(CGPoint(x: 200, y: 200)))
    }
    func testCodableRoundtripAllKinds() throws {
        let kinds: [AnnotationKind] = [
            .arrow(from: .zero, to: CGPoint(x: 1, y: 1)),
            .rectangle(CGRect(x: 1, y: 2, width: 3, height: 4)),
            .ellipse(CGRect(x: 0, y: 0, width: 5, height: 5)),
            .text(CGRect(x: 0, y: 0, width: 50, height: 20), "hi"),
            .highlighter(CGRect(x: 0, y: 0, width: 9, height: 9)),
            .blur(CGRect(x: 0, y: 0, width: 8, height: 8), radius: 12, pixelate: true),
            .stepNumber(center: CGPoint(x: 5, y: 5), number: 3),
        ]
        for k in kinds {
            let a = Annotation(kind: k, style: .default)
            let back = try JSONDecoder().decode(Annotation.self, from: JSONEncoder().encode(a))
            XCTAssertEqual(back, a)
        }
    }
}
