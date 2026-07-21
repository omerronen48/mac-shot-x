import CoreGraphics
import Foundation

// MARK: – BeautifyBackground

public enum BeautifyBackground: Equatable, Codable, Sendable {
    case solid(RGBAColor)
    case linearGradient(colors: [RGBAColor], angle: Double)
    case image(path: String)
}

// MARK: – BeautifyShadow

public struct BeautifyShadow: Equatable, Codable, Sendable {
    public var color: RGBAColor
    public var radius: Double
    public var opacity: Double
    public var offset: CGSize

    public init(color: RGBAColor, radius: Double, opacity: Double, offset: CGSize) {
        self.color = color
        self.radius = radius
        self.opacity = opacity
        self.offset = offset
    }
}

// MARK: – BeautifyPreset

public struct BeautifyPreset: Equatable, Codable, Sendable {
    public var name: String
    public var style: BeautifyStyle

    public init(name: String, style: BeautifyStyle) {
        self.name = name
        self.style = style
    }
}

// MARK: – BeautifyStyle

public struct BeautifyStyle: Equatable, Codable, Sendable {
    public var background: BeautifyBackground
    public var padding: Double
    public var cornerRadius: Double
    public var shadow: BeautifyShadow?
    public var scale: Double

    public init(
        background: BeautifyBackground,
        padding: Double,
        cornerRadius: Double,
        shadow: BeautifyShadow?,
        scale: Double
    ) {
        self.background = background
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.scale = scale
    }

    public static let none = BeautifyStyle(
        background: .solid(RGBAColor(r: 0, g: 0, b: 0, a: 0)),
        padding: 0,
        cornerRadius: 0,
        shadow: nil,
        scale: 1
    )

    public static let builtins: [BeautifyPreset] = {
        let black = RGBAColor(r: 0, g: 0, b: 0, a: 1)
        func shadow(_ opacity: Double) -> BeautifyShadow {
            BeautifyShadow(color: black, radius: 24, opacity: opacity, offset: CGSize(width: 0, height: 10))
        }
        let stdPadding: Double = 48
        let stdRadius: Double = 14
        let stdScale: Double = 2

        return [
            BeautifyPreset(name: "None", style: .none),
            BeautifyPreset(name: "White", style: BeautifyStyle(
                background: .solid(RGBAColor(r: 1, g: 1, b: 1, a: 1)),
                padding: stdPadding, cornerRadius: stdRadius,
                shadow: shadow(0.35), scale: stdScale
            )),
            BeautifyPreset(name: "Dark", style: BeautifyStyle(
                background: .solid(RGBAColor(r: 0.11, g: 0.11, b: 0.12, a: 1)),
                padding: stdPadding, cornerRadius: stdRadius,
                shadow: shadow(0.5), scale: stdScale
            )),
            BeautifyPreset(name: "Blue gradient", style: BeautifyStyle(
                background: .linearGradient(
                    colors: [RGBAColor(r: 0.2, g: 0.5, b: 1, a: 1), RGBAColor(r: 0.1, g: 0.2, b: 0.6, a: 1)],
                    angle: 135
                ),
                padding: stdPadding, cornerRadius: stdRadius,
                shadow: shadow(0.35), scale: stdScale
            )),
            BeautifyPreset(name: "Purple gradient", style: BeautifyStyle(
                background: .linearGradient(
                    colors: [RGBAColor(r: 0.5, g: 0.2, b: 0.9, a: 1), RGBAColor(r: 0.3, g: 0.1, b: 0.5, a: 1)],
                    angle: 135
                ),
                padding: stdPadding, cornerRadius: stdRadius,
                shadow: shadow(0.35), scale: stdScale
            )),
            BeautifyPreset(name: "Sunset gradient", style: BeautifyStyle(
                background: .linearGradient(
                    colors: [RGBAColor(r: 1, g: 0.5, b: 0.2, a: 1), RGBAColor(r: 0.9, g: 0.2, b: 0.4, a: 1)],
                    angle: 135
                ),
                padding: stdPadding, cornerRadius: stdRadius,
                shadow: shadow(0.35), scale: stdScale
            )),
        ]
    }()
}
