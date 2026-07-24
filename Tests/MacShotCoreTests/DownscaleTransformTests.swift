import XCTest
import CoreGraphics
@testable import MacShotCore

final class DownscaleTransformTests: XCTestCase {
    func testRetinaHalvesWhenEnabled() {
        XCTAssertEqual(DownscaleTransform.targetSize(imagePixels: CGSize(width: 2000, height: 1000), displayScale: 2, downscale: true),
                       CGSize(width: 1000, height: 500))
    }
    func testScaleOneUnchanged() {
        XCTAssertEqual(DownscaleTransform.targetSize(imagePixels: CGSize(width: 1000, height: 500), displayScale: 1, downscale: true),
                       CGSize(width: 1000, height: 500))
    }
    func testDisabledUnchanged() {
        XCTAssertEqual(DownscaleTransform.targetSize(imagePixels: CGSize(width: 2000, height: 1000), displayScale: 2, downscale: false),
                       CGSize(width: 2000, height: 1000))
    }
    func testDownsampleProducesRequestedPixelSize() {
        let ctx = CGContext(data: nil, width: 20, height: 10, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let img = ctx.makeImage()!
        let out = DownscaleTransform.downsampled(img, to: CGSize(width: 10, height: 5))
        XCTAssertEqual(out.width, 10); XCTAssertEqual(out.height, 5)
    }
}
