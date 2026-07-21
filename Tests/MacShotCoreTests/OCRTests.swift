import XCTest
import CoreGraphics
@testable import MacShotCore

private struct FakeOCR: OCRService {
    let out: [OCRObservation]
    func recognize(_ image: CGImage) async throws -> [OCRObservation] { out }
}

final class OCRTests: XCTestCase {
    func testObservationEquatable() {
        let a = OCRObservation(text: "hi", boundingBox: CGRect(x: 0, y: 0, width: 1, height: 1), confidence: 0.9)
        let b = OCRObservation(text: "hi", boundingBox: CGRect(x: 0, y: 0, width: 1, height: 1), confidence: 0.9)
        XCTAssertEqual(a, b)
    }
    func testServiceProtocolReturnsObservations() async throws {
        let obs = [OCRObservation(text: "x", boundingBox: .zero, confidence: 1)]
        let img = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!.makeImage()!
        let result = try await FakeOCR(out: obs).recognize(img)
        XCTAssertEqual(result, obs)
    }
}
