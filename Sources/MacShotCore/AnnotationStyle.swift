import CoreGraphics

/// AppKit-free color; converted to CGColor at render time (MacShotCore stays headless).
public struct RGBAColor: Equatable, Codable, Sendable {
    public var r, g, b, a: Double
    public init(r: Double, g: Double, b: Double, a: Double) { self.r = r; self.g = g; self.b = b; self.a = a }
    public var cgColor: CGColor {
        CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [r, g, b, a])
            ?? CGColor(gray: 0, alpha: a)
    }
    public static let red = RGBAColor(r: 1, g: 0.231, b: 0.188, a: 1)     // #FF3B30
    public static let yellow40 = RGBAColor(r: 1, g: 0.8, b: 0, a: 0.4)
    public static let white = RGBAColor(r: 1, g: 1, b: 1, a: 1)
}

public struct AnnotationStyle: Equatable, Codable, Sendable {
    public var strokeColor: RGBAColor
    public var fillColor: RGBAColor?
    public var lineWidth: Double
    public var fontSize: Double
    public init(strokeColor: RGBAColor, fillColor: RGBAColor?, lineWidth: Double, fontSize: Double) {
        self.strokeColor = strokeColor; self.fillColor = fillColor
        self.lineWidth = lineWidth; self.fontSize = fontSize
    }
    public static let `default` = AnnotationStyle(strokeColor: .red, fillColor: nil, lineWidth: 3, fontSize: 17)
}
