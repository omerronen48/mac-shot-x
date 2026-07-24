import XCTest
@testable import MacShotCore

final class BarcodeResultTests: XCTestCase {
    func testBarcodesTakePrecedence() {
        let result = BarcodeResult.combinedPayload(text: "ocr text", barcodes: ["https://example.com"])
        XCTAssertEqual(result, "https://example.com")
    }

    func testFallsBackToText() {
        let result = BarcodeResult.combinedPayload(text: "ocr text", barcodes: [])
        XCTAssertEqual(result, "ocr text")
    }

    func testBothEmpty() {
        let result = BarcodeResult.combinedPayload(text: "", barcodes: [])
        XCTAssertEqual(result, "")
    }

    func testLooksLikeURL() {
        XCTAssertTrue(BarcodeResult.looksLikeURL("https://apple.com"))
        XCTAssertTrue(BarcodeResult.looksLikeURL("http://apple.com"))
        XCTAssertTrue(BarcodeResult.looksLikeURL("  http://x  "))  // trimmed true
        XCTAssertFalse(BarcodeResult.looksLikeURL("ftp://x"))       // ftp is not http/https
        XCTAssertFalse(BarcodeResult.looksLikeURL("plain text"))
    }
}
