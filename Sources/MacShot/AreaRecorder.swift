import AppKit
import AVFoundation
import CoreMedia
@preconcurrency import ScreenCaptureKit

// ponytail: unchecked Sendable — all mutable state lives behind `queue` (serial);
// the SC callback arrives on that same queue; Swift 6 is satisfied.
final class AreaRecorder: NSObject, SCStreamOutput, @unchecked Sendable {

    private let queue = DispatchQueue(label: "AreaRecorder.frames", qos: .userInitiated)

    // Mutable recording state — only touched on `queue` (or before startCapture returns)
    private var stream: SCStream?
    private var writer: AVAssetWriter?
    private var input: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var outputURL: URL?
    private var sessionStarted = false
    private var frameCount = 0

    // MARK: - Public API

    func start(area: CGRect, display: SCDisplay, scale: CGFloat, to url: URL) async throws {
        outputURL = url

        // Stream configuration
        let config = SCStreamConfiguration()
        config.sourceRect = area          // display-local top-left points (matches .area(rect) convention)
        config.width  = Int((area.width  * scale).rounded())
        config.height = Int((area.height * scale).rounded())
        config.showsCursor = true
        config.capturesAudio = false
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        config.pixelFormat = kCVPixelFormatType_32BGRA

        // AVAssetWriter pipeline
        let writer = try AVAssetWriter(url: url, fileType: .mp4)
        // Screen content (sharp text/edges) needs a far higher bitrate than AVFoundation's
        // photographic default. ~0.4 bits/pixel/frame keeps text crisp; scales with the area.
        // ponytail: 0.4 bpp is the quality knob — raise for pixel-perfect, lower for smaller files.
        let bitRate = Int(Double(config.width * config.height * 30) * 0.4)
        let videoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey:  AVVideoCodecType.h264,
                AVVideoWidthKey:  config.width,
                AVVideoHeightKey: config.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: bitRate,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                    AVVideoMaxKeyFrameIntervalKey: 60
                ] as [String: Any]
            ]
        )
        videoInput.expectsMediaDataInRealTime = true
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
        )
        writer.add(videoInput)
        self.writer = writer
        self.input = videoInput
        self.adaptor = adaptor

        // SCStream
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let stream = SCStream(filter: filter, configuration: config, delegate: nil)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: queue)
        try await stream.startCapture()
        self.stream = stream
    }

    func stop() async -> URL? {
        try? await stream?.stopCapture()
        input?.markAsFinished()

        if let w = writer, w.status == .writing {
            await w.finishWriting()
        }

        let url = outputURL
        let completed = writer?.status == .completed && frameCount > 0

        // Null out stored properties
        stream = nil
        writer = nil
        input = nil
        adaptor = nil
        outputURL = nil
        sessionStarted = false
        frameCount = 0

        if completed, let url {
            return url
        } else {
            if let url { try? FileManager.default.removeItem(at: url) }
            return nil
        }
    }

    // MARK: - SCStreamOutput

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }

        // Verify frame is complete via attachment
        guard
            let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
            let first = attachments.first,
            let statusRaw = first[SCStreamFrameInfo.status] as? Int,
            let status = SCFrameStatus(rawValue: statusRaw),
            status == .complete
        else { return }

        guard
            sampleBuffer.isValid,
            CMSampleBufferDataIsReady(sampleBuffer),
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }

        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        guard let writer, let input, let adaptor else { return }

        if !sessionStarted {
            writer.startWriting()
            writer.startSession(atSourceTime: pts)
            sessionStarted = true
        }

        if input.isReadyForMoreMediaData {
            adaptor.append(pixelBuffer, withPresentationTime: pts)
            frameCount += 1
        }
    }
}
