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

public enum TextAlignment: String, Codable, Sendable { case left, center, right }

public struct AnnotationStyle: Equatable, Codable, Sendable {
    public var strokeColor: RGBAColor
    public var fillColor: RGBAColor?
    public var lineWidth: Double
    public var fontSize: Double
    public var textOutline: Bool
    public var textBackgroundColor: RGBAColor?
    public var textAlignment: TextAlignment

    public init(strokeColor: RGBAColor, fillColor: RGBAColor?, lineWidth: Double, fontSize: Double,
                textOutline: Bool = false, textBackgroundColor: RGBAColor? = nil, textAlignment: TextAlignment = .left) {
        self.strokeColor = strokeColor; self.fillColor = fillColor
        self.lineWidth = lineWidth; self.fontSize = fontSize
        self.textOutline = textOutline; self.textBackgroundColor = textBackgroundColor; self.textAlignment = textAlignment
    }

    public static let `default` = AnnotationStyle(strokeColor: .red, fillColor: nil, lineWidth: 3, fontSize: 17)

    private enum CodingKeys: String, CodingKey {
        case strokeColor, fillColor, lineWidth, fontSize, textOutline, textBackgroundColor, textAlignment
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        strokeColor = try c.decode(RGBAColor.self, forKey: .strokeColor)
        fillColor = try c.decodeIfPresent(RGBAColor.self, forKey: .fillColor)
        lineWidth = try c.decode(Double.self, forKey: .lineWidth)
        fontSize = try c.decode(Double.self, forKey: .fontSize)
        textOutline = try c.decodeIfPresent(Bool.self, forKey: .textOutline) ?? false
        textBackgroundColor = try c.decodeIfPresent(RGBAColor.self, forKey: .textBackgroundColor)
        textAlignment = try c.decodeIfPresent(TextAlignment.self, forKey: .textAlignment) ?? .left
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(strokeColor, forKey: .strokeColor)
        try c.encode(fillColor, forKey: .fillColor)
        try c.encode(lineWidth, forKey: .lineWidth)
        try c.encode(fontSize, forKey: .fontSize)
        try c.encode(textOutline, forKey: .textOutline)
        try c.encode(textBackgroundColor, forKey: .textBackgroundColor)
        try c.encode(textAlignment, forKey: .textAlignment)
    }
}
