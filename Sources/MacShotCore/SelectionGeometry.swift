import CoreGraphics

/// Pure geometry for the selection overlay. Kept in core so the AppKit overlay
/// window stays a thin renderer.
public enum SelectionGeometry {
    public static func rect(from a: CGPoint, to b: CGPoint) -> CGRect {
        CGRect(x: min(a.x, b.x), y: min(a.y, b.y),
               width: abs(a.x - b.x), height: abs(a.y - b.y))
    }
    public static func clamp(_ r: CGRect, to bounds: CGRect) -> CGRect {
        // ponytail: snap origin into bounds, then clip far edge; size only shrinks when far edge exceeds bounds
        let x = max(r.minX, bounds.minX)
        let y = max(r.minY, bounds.minY)
        let w = min(r.width, bounds.maxX - x)
        let h = min(r.height, bounds.maxY - y)
        return CGRect(x: x, y: y, width: w, height: h)
    }
    /// nil if either side is below `minSide` (treat as an accidental click).
    public static func validated(_ r: CGRect, minSide: CGFloat) -> CGRect? {
        (r.width >= minSide && r.height >= minSide) ? r : nil
    }
}
