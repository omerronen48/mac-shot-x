import CoreGraphics
import Foundation

public enum AnnotationKind: Equatable, Codable, Sendable {
    case arrow(from: CGPoint, to: CGPoint)
    case rectangle(CGRect)
    case ellipse(CGRect)
    case text(CGRect, String)
    case highlighter(CGRect)
    case blur(CGRect, radius: Double, pixelate: Bool)
    case stepNumber(center: CGPoint, number: Int)
}

public struct Annotation: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var kind: AnnotationKind
    public var style: AnnotationStyle
    public init(id: UUID = UUID(), kind: AnnotationKind, style: AnnotationStyle) {
        self.id = id; self.kind = kind; self.style = style
    }
    public var boundingBox: CGRect {
        switch kind {
        case let .arrow(from, to):
            return CGRect(x: min(from.x, to.x), y: min(from.y, to.y),
                          width: abs(from.x - to.x), height: abs(from.y - to.y))
        case let .rectangle(r), let .ellipse(r), let .highlighter(r): return r
        case let .text(r, _): return r
        case let .blur(r, _, _): return r
        case let .stepNumber(c, _):
            return CGRect(x: c.x - 16, y: c.y - 16, width: 32, height: 32)
        }
    }
    public func contains(_ p: CGPoint) -> Bool { boundingBox.insetBy(dx: -4, dy: -4).contains(p) }
}
