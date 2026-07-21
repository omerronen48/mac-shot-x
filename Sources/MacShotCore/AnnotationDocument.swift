import CoreGraphics
import Foundation

/// Ordered vector document over a base image (index order == z-order, last = front).
public struct AnnotationDocument: Codable, Equatable, Sendable {
    public var baseSize: CGSize
    public private(set) var annotations: [Annotation]
    public init(baseSize: CGSize, annotations: [Annotation] = []) {
        self.baseSize = baseSize; self.annotations = annotations
    }
    public mutating func add(_ a: Annotation) { annotations.append(a) }
    public mutating func remove(id: UUID) { annotations.removeAll { $0.id == id } }
    public mutating func update(id: UUID, _ transform: (inout Annotation) -> Void) {
        if let i = annotations.firstIndex(where: { $0.id == id }) { transform(&annotations[i]) }
    }
    public mutating func moveToFront(id: UUID) {
        guard let i = annotations.firstIndex(where: { $0.id == id }) else { return }
        annotations.append(annotations.remove(at: i))
    }
    public mutating func setAll(_ a: [Annotation]) { annotations = a }   // for undo/redo restore
    public func hitTest(_ p: CGPoint) -> UUID? {
        annotations.last(where: { $0.contains(p) })?.id
    }
    public var nextStepNumber: Int {
        annotations.reduce(0) { n, a in
            if case .stepNumber = a.kind { return n + 1 }; return n
        } + 1
    }
}
