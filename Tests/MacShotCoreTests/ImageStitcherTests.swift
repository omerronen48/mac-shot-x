import XCTest
import CoreGraphics
@testable import MacShotCore

final class ImageStitcherTests: XCTestCase {
    /// A width×(rows.count) image where row i is filled with gray = the absolute row index
    /// `rows.lowerBound + i` (so distinct rows → distinct signatures, and a scrolled frame
    /// shares signatures for the overlapping band).
    func gradient(rows: Range<Int>, width: Int = 4) -> CGImage {
        let h = rows.count
        let ctx = CGContext(data: nil, width: width, height: h, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        for (i, v) in rows.enumerated() {
            let g = CGFloat(v % 256) / 255.0
            ctx.setFillColor(red: g, green: g, blue: g, alpha: 1)
            // CGContext is bottom-left origin; row index i from the top → y = h-1-i
            ctx.fill(CGRect(x: 0, y: h - 1 - i, width: width, height: 1))
        }
        return ctx.makeImage()!
    }

    func testOverlapSuffixPrefix() {
        XCTAssertEqual(ImageStitcher.overlap([1, 2, 3, 4], [3, 4, 5, 6]), 2)
        XCTAssertEqual(ImageStitcher.overlap([1, 2, 3], [4, 5, 6]), 0)
        XCTAssertEqual(ImageStitcher.overlap([1, 2, 3], [1, 2, 3]), 3)
        XCTAssertEqual(ImageStitcher.overlap([], [1, 2]), 0)
    }
    func testRowSignaturesDistinct() {
        let sigs = ImageStitcher.rowSignatures(gradient(rows: 0..<8))
        XCTAssertEqual(sigs.count, 8)
        XCTAssertEqual(Set(sigs).count, 8)
    }
    func testStitchRemovesOverlap() {
        let a = gradient(rows: 0..<100)     // rows 0..99
        let b = gradient(rows: 50..<150)    // a scrolled down 50 → rows 50..149
        let out = ImageStitcher.stitch([a, b])
        XCTAssertEqual(out?.height, 150)    // 100 + (150-50 overlap) new rows
        XCTAssertEqual(out?.width, 4)
    }
    func testStitchSingleAndEmpty() {
        XCTAssertEqual(ImageStitcher.stitch([gradient(rows: 0..<10)])?.height, 10)
        XCTAssertNil(ImageStitcher.stitch([]))
    }
}
