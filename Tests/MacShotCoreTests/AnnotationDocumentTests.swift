import XCTest
import CoreGraphics
@testable import MacShotCore

final class AnnotationDocumentTests: XCTestCase {
    func testAddAndRemove() {
        var doc = AnnotationDocument(baseSize: CGSize(width: 100, height: 100))
        let a = Annotation(kind: .rectangle(CGRect(x: 0, y: 0, width: 10, height: 10)), style: .default)
        doc.add(a)
        XCTAssertEqual(doc.annotations.count, 1)
        doc.remove(id: a.id)
        XCTAssertTrue(doc.annotations.isEmpty)
    }
    func testHitTestReturnsTopMost() {
        var doc = AnnotationDocument(baseSize: CGSize(width: 100, height: 100))
        let bottom = Annotation(kind: .rectangle(CGRect(x: 0, y: 0, width: 50, height: 50)), style: .default)
        let top = Annotation(kind: .rectangle(CGRect(x: 0, y: 0, width: 50, height: 50)), style: .default)
        doc.add(bottom); doc.add(top)
        XCTAssertEqual(doc.hitTest(CGPoint(x: 10, y: 10)), top.id)   // last added = top
        XCTAssertNil(doc.hitTest(CGPoint(x: 90, y: 90)))
    }
    func testMoveToFront() {
        var doc = AnnotationDocument(baseSize: .zero)
        let a = Annotation(kind: .rectangle(.zero), style: .default)
        let b = Annotation(kind: .rectangle(.zero), style: .default)
        doc.add(a); doc.add(b); doc.moveToFront(id: a.id)
        XCTAssertEqual(doc.annotations.last?.id, a.id)
    }
    func testNextStepNumberIncrements() {
        var doc = AnnotationDocument(baseSize: .zero)
        XCTAssertEqual(doc.nextStepNumber, 1)
        doc.add(Annotation(kind: .stepNumber(center: .zero, number: doc.nextStepNumber), style: .default))
        XCTAssertEqual(doc.nextStepNumber, 2)
    }
    func testUpdateMutatesInPlace() {
        var doc = AnnotationDocument(baseSize: .zero)
        let a = Annotation(kind: .rectangle(.zero), style: .default)
        doc.add(a)
        doc.update(id: a.id) { $0.kind = .rectangle(CGRect(x: 5, y: 5, width: 5, height: 5)) }
        XCTAssertEqual(doc.annotations.first?.boundingBox, CGRect(x: 5, y: 5, width: 5, height: 5))
    }
}
