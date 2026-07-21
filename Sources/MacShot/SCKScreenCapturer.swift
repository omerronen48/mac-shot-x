import AppKit
import CoreGraphics
import MacShotCore
import ScreenCaptureKit

enum CaptureError: Error {
    case permissionDenied
    case noTarget
}

struct SCKScreenCapturer: ScreenCapturer {
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
            return try await captureDisplay(display)

        case .window(let windowID):
            guard let scWindow = content.windows.first(where: { $0.windowID == windowID }) else {
                throw CaptureError.noTarget
            }
            let filter = SCContentFilter(desktopIndependentWindow: scWindow)
            let config = SCStreamConfiguration()
            return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)

        case .area(let rect):
            let display = try resolveDisplay(nil, from: content)
            let full = try await captureDisplay(display)
            guard let rect else { return full }
            // `rect` is in display POINTS (top-left origin). Scale to the captured image's pixel
            // space via the actual image/point ratio so it's correct at any backing scale.
            let sx = CGFloat(full.width) / CGFloat(display.width)
            let sy = CGFloat(full.height) / CGFloat(display.height)
            let px = CGRect(x: rect.minX * sx, y: rect.minY * sy,
                            width: rect.width * sx, height: rect.height * sy).integral
            guard let cropped = full.cropping(to: px) else { throw CaptureError.noTarget }
            return cropped
        }
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

    private func captureDisplay(_ display: SCDisplay) async throws -> CGImage {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        // Capture at native pixel resolution (SCDisplay.width/height are points). Retina-sharp;
        // the area crop rescales points→pixels via the image/point ratio so it stays correct.
        let scale = displayScale(display.displayID)
        config.width = Int(CGFloat(display.width) * scale)
        config.height = Int(CGFloat(display.height) * scale)
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }

    private func displayScale(_ id: CGDirectDisplayID) -> CGFloat {
        NSScreen.screens.first {
            ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) == id
        }?.backingScaleFactor ?? 2
    }
}
