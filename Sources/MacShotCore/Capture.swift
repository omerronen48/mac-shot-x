import CoreGraphics
import Foundation

public protocol ScreenCapturer: Sendable {
    func capture(_ mode: CaptureMode) async throws -> CGImage
}

public protocol CaptureSink: Sendable {
    func copyToClipboard(_ image: CGImage)
    func writePNG(_ image: CGImage, suggestedName: String, inDirectory dir: URL) throws -> URL
}

public struct CaptureResult: Sendable {
    public let mode: CaptureMode
    public let fileURL: URL?
    public let copiedToClipboard: Bool
    public let size: CGSize
}
