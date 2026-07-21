import CoreGraphics
import Foundation
import ImageIO

// ponytail: 8192px ceiling prevents pathological memory on large 3x+ captures; raise limit only if product needs it
private let kMaxDimension: CGFloat = 8192

public enum BeautifyRenderer {

    public static func render(image: CGImage, style: BeautifyStyle) -> CGImage {
        // Fast-path passthrough for BeautifyStyle.none
        if style.padding == 0,
           case .solid(let c) = style.background, c.a == 0,
           style.shadow == nil,
           style.scale == 1 {
            return image
        }

        let pad = style.padding
        let unscaledW = CGFloat(image.width)  + pad * 2
        let unscaledH = CGFloat(image.height) + pad * 2

        // Clamp scale so neither dimension exceeds 8192 pixels
        var scale = style.scale
        let rawW0 = unscaledW * scale
        let rawH0 = unscaledH * scale
        if rawW0 > kMaxDimension || rawH0 > kMaxDimension {
            scale = kMaxDimension / max(rawW0, rawH0) * scale
        }
        // Recompute after clamp so pixelW/H reflect the reduced scale
        let rawW = unscaledW * scale
        let rawH = unscaledH * scale

        let pixelW = Int(rawW.rounded())
        let pixelH = Int(rawH.rounded())

        guard let ctx = CGContext(
            data: nil,
            width:  max(1, pixelW),
            height: max(1, pixelH),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return image }

        // Work in unscaled point space; CTM handles the final rasterisation.
        ctx.scaleBy(x: scale, y: scale)

        let canvasRect = CGRect(x: 0, y: 0, width: unscaledW, height: unscaledH)

        // 1. Draw background
        drawBackground(style.background, in: canvasRect, ctx: ctx)

        // 2. Image rect (inset by padding)
        let imageRect = CGRect(x: pad, y: pad, width: CGFloat(image.width), height: CGFloat(image.height))

        ctx.saveGState()
        if style.cornerRadius > 0 {
            let cr = style.cornerRadius
            let path = CGPath(roundedRect: imageRect, cornerWidth: cr, cornerHeight: cr, transform: nil)
            ctx.addPath(path)
            ctx.clip()
        }
        if let shadow = style.shadow {
            // CoreGraphics origin is bottom-left; positive y-offset moves shadow UP (i.e. shadow goes below the image when offset.height < 0).
            // Convention: shadow.offset.height > 0 → shadow appears below the image in screen/image coordinates.
            // We negate y because CG's y axis is flipped relative to screen/image top-down convention.
            let shadowColor = RGBAColor(
                r: shadow.color.r, g: shadow.color.g, b: shadow.color.b,
                a: shadow.color.a * shadow.opacity
            )
            ctx.setShadow(
                offset: CGSize(width: shadow.offset.width, height: -shadow.offset.height),
                blur: shadow.radius,
                color: shadowColor.cgColor
            )
        }
        ctx.draw(image, in: imageRect)
        ctx.restoreGState()

        return ctx.makeImage() ?? image
    }

    // MARK: – Background helpers

    private static func drawBackground(_ bg: BeautifyBackground, in rect: CGRect, ctx: CGContext) {
        switch bg {
        case .solid(let c):
            ctx.setFillColor(c.cgColor)
            ctx.fill(rect)

        case .linearGradient(let colors, let angle):
            guard colors.count >= 2 else {
                // Degenerate: treat as solid (first color or clear)
                let c = colors.first ?? RGBAColor(r: 0, g: 0, b: 0, a: 0)
                ctx.setFillColor(c.cgColor)
                ctx.fill(rect)
                return
            }
            let space = CGColorSpaceCreateDeviceRGB()
            let cgColors = colors.map(\.cgColor) as CFArray
            // Evenly-spaced locations
            let locs: [CGFloat] = colors.indices.map { CGFloat($0) / CGFloat(colors.count - 1) }
            guard let gradient = CGGradient(colorsSpace: space, colors: cgColors, locations: locs) else {
                ctx.setFillColor(colors[0].cgColor)
                ctx.fill(rect)
                return
            }
            // Convention: angle 0 = left→right; 90 = bottom→top (CG natural y-up direction).
            // Start/end computed from angle in degrees across the bounding rect diagonal.
            let rad = angle * .pi / 180.0
            let cx = rect.midX, cy = rect.midY
            let hw = rect.width  / 2, hh = rect.height / 2
            let dx = CGFloat(cos(rad)) * hw, dy = CGFloat(sin(rad)) * hh
            let start = CGPoint(x: cx - dx, y: cy - dy)
            let end   = CGPoint(x: cx + dx, y: cy + dy)
            ctx.drawLinearGradient(gradient, start: start, end: end,
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

        case .image(let path):
            let fallback = RGBAColor(r: 0.5, g: 0.5, b: 0.5, a: 1)
            guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
                  let bgImg = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
                ctx.setFillColor(fallback.cgColor)
                ctx.fill(rect)
                return
            }
            // Aspect-fill: scale to cover, center, clip — isolated in its own GState
            let imgW = CGFloat(bgImg.width), imgH = CGFloat(bgImg.height)
            let scaleX = rect.width  / imgW
            let scaleY = rect.height / imgH
            let fill   = max(scaleX, scaleY)
            let drawW  = imgW * fill, drawH = imgH * fill
            let drawX  = rect.minX + (rect.width  - drawW) / 2
            let drawY  = rect.minY + (rect.height - drawH) / 2
            ctx.saveGState()
            ctx.clip(to: rect)
            ctx.draw(bgImg, in: CGRect(x: drawX, y: drawY, width: drawW, height: drawH))
            ctx.restoreGState()
        }
    }
}
