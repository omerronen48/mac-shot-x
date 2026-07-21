import XCTest
import CoreGraphics
@testable import MacShotCore

final class BeautifyRendererTests: XCTestCase {

    // MARK: – Helpers

    /// Create a solid-color CGImage.
    func solidImage(_ w: Int, _ h: Int, r: Double, g: Double, b: Double) -> CGImage {
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [r, g, b, 1])!)
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        return ctx.makeImage()!
    }

    /// Read a single pixel's RGBA (0–255) by redrawing into a 1x1 context.
    /// CoreGraphics origin is bottom-left; y=0 is the top row in screen convention (CGImage stores top-down).
    func pixel(_ img: CGImage, _ x: Int, _ y: Int) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        var px: [UInt8] = [0, 0, 0, 0]
        let ctx = CGContext(data: &px, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        // Shift so (x,y) lands in the 1x1 viewport; CGImage y is top-down, CG draws bottom-up.
        ctx.draw(img, in: CGRect(x: -x, y: -(img.height - 1 - y), width: img.width, height: img.height))
        return (px[0], px[1], px[2], px[3])
    }

    /// Assert each channel is within ±tolerance.
    func assertPixel(_ img: CGImage, _ x: Int, _ y: Int,
                     r: UInt8, g: UInt8, b: UInt8, tol: UInt8 = 3,
                     file: StaticString = #file, line: UInt = #line) {
        let p = pixel(img, x, y)
        let msg = "pixel(\(x),\(y)) = (\(p.r),\(p.g),\(p.b)) expected ≈ (\(r),\(g),\(b)) ±\(tol)"
        XCTAssertTrue(abs(Int(p.r) - Int(r)) <= Int(tol), msg, file: file, line: line)
        XCTAssertTrue(abs(Int(p.g) - Int(g)) <= Int(tol), msg, file: file, line: line)
        XCTAssertTrue(abs(Int(p.b) - Int(b)) <= Int(tol), msg, file: file, line: line)
    }

    // MARK: – SIZE

    func testOutputSizeWithPadding() {
        let img = solidImage(20, 20, r: 1, g: 0, b: 0)
        let style = BeautifyStyle(background: .solid(.white), padding: 10, cornerRadius: 0, shadow: nil, scale: 1)
        let out = BeautifyRenderer.render(image: img, style: style)
        XCTAssertEqual(out.width, 40)   // 20 + 2*10
        XCTAssertEqual(out.height, 40)
    }

    // MARK: – SCALE

    func testOutputSizeWithScale() {
        let img = solidImage(20, 20, r: 1, g: 0, b: 0)
        let style = BeautifyStyle(background: .solid(.white), padding: 10, cornerRadius: 0, shadow: nil, scale: 2)
        let out = BeautifyRenderer.render(image: img, style: style)
        XCTAssertEqual(out.width, 80)   // (20 + 2*10) * 2
        XCTAssertEqual(out.height, 80)
    }

    // MARK: – CORNER PIXEL == BACKGROUND

    func testCornerPixelMatchesBackground() {
        // Background: RGBAColor(r:0.2, g:0.4, b:0.8) → (51, 102, 204) in UInt8
        let img = solidImage(20, 20, r: 1, g: 1, b: 1)
        let bg = RGBAColor(r: 0.2, g: 0.4, b: 0.8, a: 1)
        let style = BeautifyStyle(background: .solid(bg), padding: 10, cornerRadius: 0, shadow: nil, scale: 1)
        let out = BeautifyRenderer.render(image: img, style: style)
        assertPixel(out, 0, 0, r: 51, g: 102, b: 204, tol: 4)
    }

    // MARK: – PASSTHROUGH

    func testPassthrough() {
        let img = solidImage(20, 20, r: 0.5, g: 0.5, b: 0.5)
        let out = BeautifyRenderer.render(image: img, style: .none)
        XCTAssertEqual(out.width, 20)
        XCTAssertEqual(out.height, 20)
    }

    // MARK: – SHADOW PRESENT

    func testShadowChangesPaddingBand() {
        let img = solidImage(20, 20, r: 1, g: 1, b: 1)
        let whiteBg = BeautifyStyle(background: .solid(.white), padding: 20, cornerRadius: 0, shadow: nil, scale: 1)
        let shadow = BeautifyShadow(color: RGBAColor(r: 0, g: 0, b: 0, a: 1), radius: 6, opacity: 0.8,
                                    offset: CGSize(width: 0, height: 0))
        let shadowStyle = BeautifyStyle(background: .solid(.white), padding: 20, cornerRadius: 0, shadow: shadow, scale: 1)

        let plain = BeautifyRenderer.render(image: img, style: whiteBg)
        let shadowed = BeautifyRenderer.render(image: img, style: shadowStyle)

        // Sample a pixel just inside the padding band, 2px from the image edge.
        // The image starts at (padding, padding) = (20, 20), so (18, 18) is in the padding zone.
        // With shadow radius 6 and zero offset, the shadow bleeds outward in all directions.
        let px = 18  // 2px inside padding from the image corner
        let plain_p = pixel(plain, px, px)
        let shadow_p = pixel(shadowed, px, px)

        // Shadow should darken the padding region noticeably (>10 counts difference in any channel)
        let diff = abs(Int(plain_p.r) - Int(shadow_p.r))
        XCTAssertGreaterThan(diff, 10, "shadow should darken pixel (\(px),\(px)): plain=\(plain_p.r), shadowed=\(shadow_p.r)")
    }

    // MARK: – GRADIENT DEGENERATE

    func testGradientEmptyColorsNocrash() {
        let img = solidImage(10, 10, r: 0.5, g: 0.5, b: 0.5)
        let style = BeautifyStyle(background: .linearGradient(colors: [], angle: 0), padding: 5, cornerRadius: 0, shadow: nil, scale: 1)
        let out = BeautifyRenderer.render(image: img, style: style)
        // No crash and correct size: (10 + 2*5) * 1 = 20
        XCTAssertEqual(out.width, 20)
        XCTAssertEqual(out.height, 20)
    }

    func testGradientSingleColorCornerPixel() {
        let img = solidImage(20, 20, r: 1, g: 1, b: 1)
        let color = RGBAColor(r: 1, g: 0, b: 0, a: 1)   // red
        let style = BeautifyStyle(background: .linearGradient(colors: [color], angle: 0), padding: 10, cornerRadius: 0, shadow: nil, scale: 1)
        let out = BeautifyRenderer.render(image: img, style: style)
        // Single-color gradient treated as solid — corner should be red
        assertPixel(out, 0, 0, r: 255, g: 0, b: 0, tol: 5)
    }
}
