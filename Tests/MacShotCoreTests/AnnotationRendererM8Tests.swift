import XCTest
import CoreGraphics
@testable import MacShotCore

final class AnnotationRendererM8Tests: XCTestCase {
    func whiteBase(_ w: Int, _ h: Int) -> CGImage {
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(gray: 1, alpha: 1); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h)); return ctx.makeImage()!
    }
    func pixel(_ img: CGImage, x: Int, y: Int) -> (UInt8, UInt8, UInt8, UInt8) {
        var px: [UInt8] = [0,0,0,0]
        let ctx = CGContext(data: &px, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(img, in: CGRect(x: -x, y: -(img.height - 1 - y), width: img.width, height: img.height))
        return (px[0], px[1], px[2], px[3])
    }

    func testLineStrokePaintsPixels() {
        let base = whiteBase(20, 20)
        var doc = AnnotationDocument(baseSize: CGSize(width: 20, height: 20))
        var style = AnnotationStyle.default; style.strokeColor = .red; style.lineWidth = 4
        doc.add(Annotation(kind: .line(from: CGPoint(x: 0, y: 10), to: CGPoint(x: 20, y: 10)), style: style))
        let out = AnnotationRenderer.flatten(base: base, document: doc)
        let (r, g, b, _) = pixel(out, x: 10, y: 10)
        XCTAssertGreaterThan(r, 150); XCTAssertLessThan(g, 120); XCTAssertLessThan(b, 120)
    }
    func testSolidCensorFullyCovers() {
        let base = whiteBase(20, 20)
        var doc = AnnotationDocument(baseSize: CGSize(width: 20, height: 20))
        var style = AnnotationStyle.default; style.fillColor = RGBAColor(r: 0, g: 0, b: 0, a: 1)
        doc.add(Annotation(kind: .solidCensor(CGRect(x: 4, y: 4, width: 12, height: 12)), style: style))
        let out = AnnotationRenderer.flatten(base: base, document: doc)
        let (r, g, b, a) = pixel(out, x: 10, y: 10)
        XCTAssertLessThan(r, 30); XCTAssertLessThan(g, 30); XCTAssertLessThan(b, 30); XCTAssertGreaterThan(a, 200)
    }
    func testTextBackgroundFills() {
        let base = whiteBase(60, 30)
        var doc = AnnotationDocument(baseSize: CGSize(width: 60, height: 30))
        var style = AnnotationStyle.default; style.textBackgroundColor = RGBAColor(r: 1, g: 1, b: 0, a: 1)
        doc.add(Annotation(kind: .text(CGRect(x: 5, y: 5, width: 50, height: 20), "hi"), style: style))
        let out = AnnotationRenderer.flatten(base: base, document: doc)
        let (r, g, b, _) = pixel(out, x: 8, y: 15)   // inside the bg rect
        XCTAssertGreaterThan(r, 180); XCTAssertGreaterThan(g, 180); XCTAssertLessThan(b, 120)
    }
    func testEmojiFlattenSameSizeNoCrash() {
        let base = whiteBase(40, 40)
        var doc = AnnotationDocument(baseSize: CGSize(width: 40, height: 40))
        doc.add(Annotation(kind: .emoji(center: CGPoint(x: 20, y: 20), string: "😀", size: 24), style: .default))
        let out = AnnotationRenderer.flatten(base: base, document: doc)
        XCTAssertEqual(out.width, 40); XCTAssertEqual(out.height, 40)
    }
}
