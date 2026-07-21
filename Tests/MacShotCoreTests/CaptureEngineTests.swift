import XCTest
import CoreGraphics
@testable import MacShotCore

private func makeImage() -> CGImage {
    let ctx = CGContext(data: nil, width: 2, height: 2, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    return ctx.makeImage()!
}

fileprivate final class FakeCapturer: ScreenCapturer, @unchecked Sendable {
    var received: CaptureMode?; var throwErr: Error?
    func capture(_ mode: CaptureMode) async throws -> CGImage {
        received = mode; if let e = throwErr { throw e }; return makeImage()
    }
}
fileprivate final class FakeSink: CaptureSink, @unchecked Sendable {
    var clipboardCalls = 0; var written: [URL] = []
    func copyToClipboard(_ image: CGImage) { clipboardCalls += 1 }
    func writePNG(_ image: CGImage, suggestedName: String, inDirectory dir: URL) throws -> URL {
        let url = dir.appendingPathComponent(suggestedName); written.append(url); return url
    }
}

final class CaptureEngineTests: XCTestCase {
    fileprivate func makeEngine() -> (CaptureEngine, FakeCapturer, FakeSink) {
        let prefs = Preferences(store: InMemoryKVStore())
        let cap = FakeCapturer(); let sink = FakeSink()
        return (CaptureEngine(capturer: cap, sink: sink, preferences: prefs), cap, sink)
    }
    func testFullscreenRoutesToCapturerAndBothSinks() async throws {
        let (engine, cap, sink) = makeEngine()
        let result = try await engine.capture(.fullscreen(nil), at: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(cap.received, .fullscreen(nil))
        XCTAssertEqual(sink.clipboardCalls, 1)
        XCTAssertEqual(sink.written.count, 1)
        XCTAssertNotNil(result.fileURL)
    }
    func testCapturerErrorFiresNoSink() async {
        let (engine, cap, sink) = makeEngine()
        cap.throwErr = NSError(domain: "x", code: 1)
        do { _ = try await engine.capture(.area(.zero), at: Date()); XCTFail("should throw") }
        catch { XCTAssertEqual(sink.clipboardCalls, 0); XCTAssertEqual(sink.written.count, 0) }
    }
    func testRespectsClipboardOnlyPreference() async throws {
        let prefs = Preferences(store: InMemoryKVStore()); prefs.saveToFile = false
        let cap = FakeCapturer(); let sink = FakeSink()
        let engine = CaptureEngine(capturer: cap, sink: sink, preferences: prefs)
        let result = try await engine.capture(.fullscreen(nil), at: Date())
        XCTAssertEqual(sink.clipboardCalls, 1)
        XCTAssertEqual(sink.written.count, 0)
        XCTAssertNil(result.fileURL)
    }
}
