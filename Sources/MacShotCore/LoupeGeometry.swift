import CoreGraphics

/// Geometry for the magnifier loupe. The overlay samples a CACHED screen snapshot at
/// `sampleRect` and draws it into `loupeRect` — no live view sampling (no recursion).
public enum LoupeGeometry {
    /// Source region (in the snapshot's coordinate space) magnified into the loupe.
    public static func sampleRect(cursor: CGPoint, magnification: Double, loupeSize: Double) -> CGRect {
        let side = loupeSize / max(1, magnification)
        return CGRect(x: cursor.x - side / 2, y: cursor.y - side / 2, width: side, height: side)
    }
    /// On-screen loupe placement, offset from the cursor and clamped fully inside `bounds`.
    public static func loupeRect(cursor: CGPoint, loupeSize: Double, in bounds: CGRect) -> CGRect {
        let s = CGFloat(loupeSize), offset: CGFloat = 24
        var x = cursor.x + offset, y = cursor.y + offset
        x = min(x, bounds.maxX - s); y = min(y, bounds.maxY - s)
        x = max(bounds.minX, x);     y = max(bounds.minY, y)
        return CGRect(x: x, y: y, width: s, height: s)
    }
}
