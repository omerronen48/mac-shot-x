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
            guard let cropped = full.cropping(to: rect) else { throw CaptureError.noTarget }
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
        config.width = display.width
        config.height = display.height
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }
}
