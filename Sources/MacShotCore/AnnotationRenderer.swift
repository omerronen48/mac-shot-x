import CoreGraphics
import CoreImage
import CoreText
import Foundation

public enum AnnotationRenderer {
    public static func flatten(base: CGImage, document: AnnotationDocument) -> CGImage {
        let w = base.width, h = base.height
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(base, in: CGRect(x: 0, y: 0, width: w, height: h))
        for a in document.annotations { draw(a, in: ctx, base: base) }
        return ctx.makeImage() ?? base
    }

    private static func draw(_ a: Annotation, in ctx: CGContext, base: CGImage) {
        ctx.saveGState(); defer { ctx.restoreGState() }
        ctx.setStrokeColor(a.style.strokeColor.cgColor)
        ctx.setLineWidth(a.style.lineWidth)
        switch a.kind {
        case let .rectangle(r):
            if let f = a.style.fillColor { ctx.setFillColor(f.cgColor); ctx.fill(r) }
            ctx.stroke(r)
        case let .ellipse(r):
            if let f = a.style.fillColor { ctx.setFillColor(f.cgColor); ctx.fillEllipse(in: r) }
            ctx.strokeEllipse(in: r)
        case let .arrow(from, to):
            drawArrow(from: from, to: to, in: ctx, width: a.style.lineWidth)
        case let .highlighter(r):
            ctx.setFillColor(a.style.strokeColor.cgColor)
            ctx.setBlendMode(.multiply); ctx.fill(r)
        case let .text(r, s):
            drawText(s, in: r, ctx: ctx, style: a.style)
        case let .blur(r, radius, pixelate):
            drawBlur(region: r, radius: radius, pixelate: pixelate, in: ctx, base: base)
        case let .stepNumber(c, n):
            drawStep(center: c, number: n, in: ctx, style: a.style)
        case let .line(from, to):
            ctx.move(to: from); ctx.addLine(to: to); ctx.strokePath()
        case let .solidCensor(r):
            ctx.setFillColor(a.style.strokeColor.cgColor); ctx.fill(r)
        case let .emoji(c, s, size):
            let r = CGRect(x: c.x - size/2, y: c.y - size/2, width: size, height: size)
            drawText(s, in: r, ctx: ctx, style: a.style)
        }
    }

    private static func drawArrow(from: CGPoint, to: CGPoint, in ctx: CGContext, width: Double) {
        ctx.move(to: from); ctx.addLine(to: to); ctx.strokePath()
        let angle = atan2(to.y - from.y, to.x - from.x); let head = max(10, width * 4)
        ctx.move(to: to)
        ctx.addLine(to: CGPoint(x: to.x - head * cos(angle - .pi/6), y: to.y - head * sin(angle - .pi/6)))
        ctx.move(to: to)
        ctx.addLine(to: CGPoint(x: to.x - head * cos(angle + .pi/6), y: to.y - head * sin(angle + .pi/6)))
        ctx.strokePath()
    }

    private static func drawText(_ s: String, in r: CGRect, ctx: CGContext, style: AnnotationStyle) {
        // ponytail: CoreText CFAttributedString to stay AppKit-free (NSAttributedString.Key.foregroundColor only accepts NSColor under AppKit)
        let font = CTFontCreateWithName("Helvetica" as CFString, style.fontSize, nil)
        let attrs: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: style.strokeColor.cgColor,
        ]
        let cfAttr = CFAttributedStringCreate(nil, s as CFString, attrs as CFDictionary)!
        let line = CTLineCreateWithAttributedString(cfAttr)
        ctx.textPosition = CGPoint(x: r.minX, y: r.minY + style.fontSize)
        CTLineDraw(line, ctx)
    }

    private static func drawStep(center c: CGPoint, number n: Int, in ctx: CGContext, style: AnnotationStyle) {
        let d = 32.0; let rect = CGRect(x: c.x - d/2, y: c.y - d/2, width: d, height: d)
        ctx.setFillColor(style.strokeColor.cgColor); ctx.fillEllipse(in: rect)
        drawText("\(n)", in: CGRect(x: rect.minX + 9, y: rect.minY + 4, width: d, height: d),
                 ctx: ctx, style: AnnotationStyle(strokeColor: .white, fillColor: nil, lineWidth: 1, fontSize: 18))
    }

    private static func drawBlur(region: CGRect, radius: Double, pixelate: Bool, in ctx: CGContext, base: CGImage) {
        let clamped = region.intersection(CGRect(x: 0, y: 0, width: base.width, height: base.height))
        guard !clamped.isNull, clamped.width > 0, clamped.height > 0 else { return }
        // ponytail: clampedToExtent prevents alpha-zero edges from CIGaussianBlur's extent falloff
        let ci = CIImage(cgImage: base).clampedToExtent()
        let filter: CIFilter? = pixelate
            ? CIFilter(name: "CIPixellate", parameters: [kCIInputImageKey: ci, kCIInputScaleKey: max(2, radius)])
            : CIFilter(name: "CIGaussianBlur", parameters: [kCIInputImageKey: ci, kCIInputRadiusKey: radius])
        guard let out = filter?.outputImage else { return }
        let cictx = CIContext()
        let originalExtent = CIImage(cgImage: base).extent
        guard let blurred = cictx.createCGImage(out, from: originalExtent) else { return }
        ctx.saveGState()
        ctx.clip(to: clamped)
        ctx.draw(blurred, in: CGRect(x: 0, y: 0, width: base.width, height: base.height))
        ctx.restoreGState()
    }
}
