import CoreGraphics
import Foundation

/// The single entry point for every capture. Routes the mode to the capturer,
/// then fans out to the sinks per preferences. UI (overlay) resolves the mode's
/// associated values before calling this.
public struct CaptureEngine {
    private let capturer: ScreenCapturer
    private let sink: CaptureSink
    private let preferences: Preferences

    public init(capturer: ScreenCapturer, sink: CaptureSink, preferences: Preferences) {
        self.capturer = capturer; self.sink = sink; self.preferences = preferences
    }

    @discardableResult
    public func capture(_ mode: CaptureMode, at date: Date = Date()) async throws -> CaptureResult {
        let image = try await capturer.capture(mode)

        var copied = false
        if preferences.copyToClipboard { sink.copyToClipboard(image); copied = true }

        var fileURL: URL?
        if preferences.saveToFile {
            let dir = URL(fileURLWithPath: preferences.saveDirectoryPath, isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let formatter = FilenameFormatter(format: preferences.filenameFormat)
            let name = formatter.uniqueFilename(for: date, mode: mode.slug) {
                FileManager.default.fileExists(atPath: dir.appendingPathComponent($0).path)
            }
            fileURL = try sink.writePNG(image, suggestedName: name, inDirectory: dir)
        }
        return CaptureResult(mode: mode, image: image, fileURL: fileURL,
                             copiedToClipboard: copied,
                             size: CGSize(width: image.width, height: image.height))
    }
}
