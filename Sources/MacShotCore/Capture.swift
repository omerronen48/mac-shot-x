import CoreGraphics
import Foundation

public protocol ScreenCapturer: Sendable {
    func capture(_ mode: CaptureMode) async throws -> CGImage
}

public protocol CaptureSink: Sendable {
    func copyToClipboard(_ image: CGImage)
    func writePNG(_ image: CGImage, suggestedName: String, inDirectory dir: URL) throws -> URL
}

public struct CaptureResult: @unchecked Sendable {   // CGImage is immutable/thread-safe, just un-annotated
    public let mode: CaptureMode
    public let image: CGImage
    public let fileURL: URL?
    public let copiedToClipboard: Bool
    public let size: CGSize
}
