import AppKit
import CoreGraphics
import Foundation
import MacShotCore

enum SystemSinkError: Error {
    case pngEncodingFailed
}

// ponytail: stateless struct — Sendable conformance is free, no annotations needed
struct SystemSink: CaptureSink {
    func copyToClipboard(_ image: CGImage) {
        let nsImage = NSImage(cgImage: image, size: .zero)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([nsImage])
    }

    func writePNG(_ image: CGImage, suggestedName: String, inDirectory dir: URL) throws -> URL {
        guard let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            throw SystemSinkError.pngEncodingFailed
        }
        let url = dir.appendingPathComponent(suggestedName)
        try data.write(to: url)
        return url
    }
}
