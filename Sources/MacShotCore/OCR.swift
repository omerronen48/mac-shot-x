import CoreGraphics

/// One recognized text fragment. boundingBox is in image pixel space (origin bottom-left).
public struct OCRObservation: Equatable, Sendable {
    public var text: String
    public var boundingBox: CGRect
    public var confidence: Double
    public init(text: String, boundingBox: CGRect, confidence: Double) {
        self.text = text; self.boundingBox = boundingBox; self.confidence = confidence
    }
}

public protocol OCRService: Sendable {
    func recognize(_ image: CGImage) async throws -> [OCRObservation]
}
