import XCTest
import CoreGraphics
@testable import MacShotCore

final class AnnotationM8Tests: XCTestCase {
    func testLineBoundingBoxSpansEndpoints() {
        let a = Annotation(kind: .line(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 10, y: 5)), style: .default)
        XCTAssertEqual(a.boundingBox, CGRect(x: 0, y: 0, width: 10, height: 5))
    }
    func testSolidCensorBoundingBox() {
        let a = Annotation(kind: .solidCensor(CGRect(x: 1, y: 2, width: 3, height: 4)), style: .default)
        XCTAssertEqual(a.boundingBox, CGRect(x: 1, y: 2, width: 3, height: 4))
    }
    func testEmojiContainsCenter() {
        let a = Annotation(kind: .emoji(center: CGPoint(x: 50, y: 50), string: "😀", size: 40), style: .default)
        XCTAssertTrue(a.contains(CGPoint(x: 50, y: 50)))
    }
    func testCodableRoundtripNewKinds() throws {
        let kinds: [AnnotationKind] = [
            .line(from: .zero, to: CGPoint(x: 1, y: 1)),
            .solidCensor(CGRect(x: 0, y: 0, width: 5, height: 5)),
            .emoji(center: CGPoint(x: 2, y: 2), string: "🎯", size: 30),
        ]
        for k in kinds {
            let a = Annotation(kind: k, style: .default)
            XCTAssertEqual(try JSONDecoder().decode(Annotation.self, from: JSONEncoder().encode(a)), a)
        }
    }
}
