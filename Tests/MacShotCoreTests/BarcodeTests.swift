import XCTest
import CoreGraphics
@testable import MacShotCore

private struct FakeBarcode: BarcodeService {
    let out: [BarcodeObservation]
    func detect(_ image: CGImage) async throws -> [BarcodeObservation] { out }
}

final class BarcodeTests: XCTestCase {
    func testObservationEquatable() {
        let a = BarcodeObservation(payload: "hi", symbology: "QR", boundingBox: .zero)
        let b = BarcodeObservation(payload: "hi", symbology: "QR", boundingBox: .zero)
        XCTAssertEqual(a, b)
    }
    func testServiceReturnsObservations() async throws {
        let obs = [BarcodeObservation(payload: "https://x", symbology: "QR", boundingBox: .zero)]
        let img = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!.makeImage()!
        let r = try await FakeBarcode(out: obs).detect(img)
        XCTAssertEqual(r, obs)
    }
}
