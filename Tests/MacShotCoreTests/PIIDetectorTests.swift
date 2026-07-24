import XCTest
import CoreGraphics
@testable import MacShotCore

final class PIIDetectorTests: XCTestCase {

    // MARK: - matches() TRUE

    func testMatchesEmail() {
        XCTAssertTrue(PIIDetector.matches("john@example.com"))
    }

    func testMatchesPhoneParens() {
        XCTAssertTrue(PIIDetector.matches("(555) 123-4567"))
    }

    func testMatchesPhoneDashes() {
        XCTAssertTrue(PIIDetector.matches("555-123-4567"))
    }

    func testMatchesCreditCard16() {
        XCTAssertTrue(PIIDetector.matches("4111 1111 1111 1111"))
    }

    func testMatchesCreditCard13() {
        XCTAssertTrue(PIIDetector.matches("4111 1111 1111"))
    }

    func testMatchesAPIKey() {
        XCTAssertTrue(PIIDetector.matches("sk_live_abc123XYZ456def789"))
    }

    // MARK: - matches() FALSE

    func testNoMatchHelloWorld() {
        XCTAssertFalse(PIIDetector.matches("hello world"))
    }

    func testNoMatch42() {
        XCTAssertFalse(PIIDetector.matches("42"))
    }

    func testNoMatchJustSomeText() {
        XCTAssertFalse(PIIDetector.matches("just some text"))
    }

    // MARK: - detect()

    func testDetectReturnsPIIBoxesInOrder() {
        let emailBox = CGRect(x: 0, y: 0, width: 100, height: 20)
        let phoneBox = CGRect(x: 0, y: 30, width: 100, height: 20)
        let cardBox  = CGRect(x: 0, y: 60, width: 100, height: 20)
        let noneBox  = CGRect(x: 0, y: 90, width: 100, height: 20)

        let observations: [OCRObservation] = [
            OCRObservation(text: "john@example.com",   boundingBox: emailBox, confidence: 1),
            OCRObservation(text: "hello world",         boundingBox: noneBox,  confidence: 1),
            OCRObservation(text: "(555) 123-4567",      boundingBox: phoneBox, confidence: 1),
            OCRObservation(text: "4111 1111 1111 1111", boundingBox: cardBox,  confidence: 1),
        ]

        let result = PIIDetector.detect(observations)
        XCTAssertEqual(result, [emailBox, phoneBox, cardBox])
    }

    func testDetectDeduplicatesSameBoundingBox() {
        let sharedBox = CGRect(x: 5, y: 5, width: 200, height: 20)

        let observations: [OCRObservation] = [
            OCRObservation(text: "john@example.com",   boundingBox: sharedBox, confidence: 1),
            OCRObservation(text: "(555) 123-4567",      boundingBox: sharedBox, confidence: 1),
        ]

        let result = PIIDetector.detect(observations)
        XCTAssertEqual(result, [sharedBox])
    }
}
