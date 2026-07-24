import CoreGraphics

public struct BarcodeObservation: Equatable, Sendable {
    public let payload: String
    public let symbology: String
    public let boundingBox: CGRect

    public init(payload: String, symbology: String, boundingBox: CGRect) {
        self.payload = payload
        self.symbology = symbology
        self.boundingBox = boundingBox
    }
}

public protocol BarcodeService: Sendable {
    func detect(_ image: CGImage) async throws -> [BarcodeObservation]
}
