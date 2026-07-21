import XCTest
import CoreGraphics
@testable import MacShotCore

final class AnnotationRendererTests: XCTestCase {
    /// A solid-white base image.
    func whiteBase(_ w: Int, _ h: Int) -> CGImage {
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(gray: 1, alpha: 1); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        return ctx.makeImage()!
    }
    /// Read a single pixel's RGBA (0–255) by redrawing into a 1x1 context.
    func pixel(_ img: CGImage, x: Int, y: Int) -> (UInt8, UInt8, UInt8, UInt8) {
        var px: [UInt8] = [0, 0, 0, 0]
        let ctx = CGContext(data: &px, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(img, in: CGRect(x: -x, y: -(img.height - 1 - y), width: img.width, height: img.height))
        return (px[0], px[1], px[2], px[3])
    }

    func testEmptyDocKeepsBaseSize() {
        let base = whiteBase(20, 10)
        let out = AnnotationRenderer.flatten(base: base, document: AnnotationDocument(baseSize: CGSize(width: 20, height: 10)))
        XCTAssertEqual(out.width, 20); XCTAssertEqual(out.height, 10)
    }
    func testFilledRectPaintsPixels() {
        let base = whiteBase(20, 20)
        var doc = AnnotationDocument(baseSize: CGSize(width: 20, height: 20))
        var style = AnnotationStyle.default; style.fillColor = .red
        doc.add(Annotation(kind: .rectangle(CGRect(x: 4, y: 4, width: 12, height: 12)), style: style))
        let out = AnnotationRenderer.flatten(base: base, document: doc)
        let (r, g, b, _) = pixel(out, x: 10, y: 10)   // inside the rect
        XCTAssertGreaterThan(r, 180); XCTAssertLessThan(g, 120); XCTAssertLessThan(b, 120)  // red-dominant
    }
    func testBlurChangesRegion() {
        // Base: left half black, right half white -> a sharp edge; blur should gray the seam.
        let ctx = CGContext(data: nil, width: 20, height: 20, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(gray: 0, alpha: 1); ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 20))
        ctx.setFillColor(gray: 1, alpha: 1); ctx.fill(CGRect(x: 10, y: 0, width: 10, height: 20))
        let base = ctx.makeImage()!
        var doc = AnnotationDocument(baseSize: CGSize(width: 20, height: 20))
        doc.add(Annotation(kind: .blur(CGRect(x: 5, y: 5, width: 10, height: 10), radius: 8, pixelate: false), style: .default))
        let out = AnnotationRenderer.flatten(base: base, document: doc)
        let (r, _, _, _) = pixel(out, x: 10, y: 10)    // at the seam, inside the blur region
        XCTAssertTrue(r > 20 && r < 235, "blurred seam should be mid-gray, got \(r)")
    }
}
