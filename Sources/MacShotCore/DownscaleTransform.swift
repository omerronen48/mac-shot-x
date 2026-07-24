import CoreGraphics

/// Optional Retina downscale: halve the pixel dimensions on hi-DPI displays (~4× fewer pixels).
public enum DownscaleTransform {
    public static func targetSize(imagePixels: CGSize, displayScale: CGFloat, downscale: Bool) -> CGSize {
        guard downscale, displayScale > 1 else { return imagePixels }
        return CGSize(width: (imagePixels.width / displayScale).rounded(),
                      height: (imagePixels.height / displayScale).rounded())
    }
    public static func downsampled(_ image: CGImage, to size: CGSize) -> CGImage {
        let w = max(1, Int(size.width)), h = max(1, Int(size.height))
        guard w != image.width || h != image.height,
              let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return image }
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return ctx.makeImage() ?? image
    }
}
