import CoreGraphics

/// Geometry for pinned floating windows.
public enum PinGeometry {
    public static func clampOpacity(_ v: Double) -> Double { min(1.0, max(0.2, v)) }

    /// Aspect-fit the image into a box `maxFraction` of the screen (never upscaling), centered.
    public static func initialFrame(imageSize: CGSize, screen: CGRect, maxFraction: CGFloat = 0.5) -> CGRect {
        let maxW = screen.width * maxFraction, maxH = screen.height * maxFraction
        let scale = min(maxW / imageSize.width, maxH / imageSize.height, 1)
        let w = imageSize.width * scale, h = imageSize.height * scale
        return CGRect(x: screen.minX + (screen.width - w) / 2,
                      y: screen.minY + (screen.height - h) / 2, width: w, height: h)
    }
}
