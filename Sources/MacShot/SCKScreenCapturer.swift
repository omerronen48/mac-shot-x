import AppKit
import CoreGraphics
import MacShotCore
@preconcurrency import ScreenCaptureKit

enum CaptureError: Error {
    case permissionDenied
    case noTarget
}

struct SCKScreenCapturer: ScreenCapturer {
    // ponytail: nonisolated(unsafe) — Preferences holds a KeyValueStore class (not Sendable);
    // this struct crosses async boundaries but is sole-owner value type; AppDelegate owns
    // it on the main actor. Mirror pattern from CaptureEngine.
    nonisolated(unsafe) let prefs: Preferences

    init(prefs: Preferences = Preferences(store: UserDefaults.standard)) {
        self.prefs = prefs
    }

    func capture(_ mode: CaptureMode) async throws -> CGImage {
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.current
        } catch {
            throw CaptureError.permissionDenied
        }

        switch mode {
        case .fullscreen(let displayID):
            let display = try resolveDisplay(displayID, from: content)
            return try await captureDisplay(display, downscale: prefs.downscaleRetina)

        case .window(let windowID):
            guard let scWindow = content.windows.first(where: { $0.windowID == windowID }) else {
                throw CaptureError.noTarget
            }
            let filter = SCContentFilter(desktopIndependentWindow: scWindow)
            let config = SCStreamConfiguration()
            config.showsCursor = prefs.captureCursor
            return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)

        case .area(let rect):
            let display = try resolveDisplay(nil, from: content)
            let full = try await captureDisplay(display, downscale: false)
            guard let rect else { return full }
            // `rect` is in display POINTS (top-left origin). Scale to the captured image's pixel
            // space via the actual image/point ratio so it's correct at any backing scale.
            let sx = CGFloat(full.width) / CGFloat(display.width)
            let sy = CGFloat(full.height) / CGFloat(display.height)
            let px = CGRect(x: rect.minX * sx, y: rect.minY * sy,
                            width: rect.width * sx, height: rect.height * sy).integral
            guard let cropped = full.cropping(to: px) else { throw CaptureError.noTarget }
            if prefs.downscaleRetina {
                let scale = displayScale(display.displayID)
                let target = DownscaleTransform.targetSize(
                    imagePixels: CGSize(width: cropped.width, height: cropped.height),
                    displayScale: scale, downscale: true)
                return DownscaleTransform.downsampled(cropped, to: target)
            }
            return cropped
        }
    }

    /// Captures the main display at native pixels (no downscale). Used for loupe snapshots.
    public func captureDisplayImage() async throws -> CGImage {
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.current
        } catch {
            throw CaptureError.permissionDenied
        }
        let display = try resolveDisplay(nil, from: content)
        return try await captureDisplay(display, downscale: false)
    }

    // MARK: - Helpers

    private func resolveDisplay(_ displayID: CGDirectDisplayID?, from content: SCShareableContent) throws -> SCDisplay {
        if let id = displayID {
            guard let d = content.displays.first(where: { $0.displayID == id }) else {
                throw CaptureError.noTarget
            }
            return d
        }
        let mainID = CGMainDisplayID()
        guard let d = content.displays.first(where: { $0.displayID == mainID })
                   ?? content.displays.first else {
            throw CaptureError.noTarget
        }
        return d
    }

    private func captureDisplay(_ display: SCDisplay, downscale: Bool) async throws -> CGImage {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        // Capture at native pixel resolution (SCDisplay.width/height are points). Retina-sharp;
        // the area crop rescales points→pixels via the image/point ratio so it stays correct.
        let scale = displayScale(display.displayID)
        config.width = Int(CGFloat(display.width) * scale)
        config.height = Int(CGFloat(display.height) * scale)
        config.showsCursor = prefs.captureCursor
        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        guard downscale else { return image }
        let target = DownscaleTransform.targetSize(
            imagePixels: CGSize(width: image.width, height: image.height),
            displayScale: scale, downscale: true)
        return DownscaleTransform.downsampled(image, to: target)
    }

    private func displayScale(_ id: CGDirectDisplayID) -> CGFloat {
        NSScreen.screens.first {
            ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) == id
        }?.backingScaleFactor ?? 2
    }
}
