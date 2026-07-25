import AppKit
import CoreGraphics
import MacShotCore
@preconcurrency import ScreenCaptureKit

@MainActor final class ScrollCaptureCoordinator {
    // ponytail: plain let — SCKScreenCapturer is a struct (Sendable); no nonisolated(unsafe) needed
    let capturer: SCKScreenCapturer
    let permission: PermissionFlow
    let present: (CGImage) async -> Void

    init(capturer: SCKScreenCapturer, permission: PermissionFlow, present: @escaping (CGImage) async -> Void) {
        self.capturer = capturer
        self.permission = permission
        self.present = present
    }

    func run() async {
        // 1. Screen access
        if !permission.hasScreenAccess() {
            permission.requestScreenAccess()
            if !permission.hasScreenAccess() {
                permission.openScreenRecordingSettings()
                return
            }
        }

        // 2. Window under cursor
        guard let (windowID, windowFrame) = await windowUnderCursor() else { return }

        // 3. Scroll-capture loop
        var frames: [CGImage] = []
        // ponytail: ½ frame-height in points, min 1; negative wheel1 = scroll down
        let scrollLines = max(1, Int(windowFrame.height / 2))

        for _ in 0..<30 {
            guard let frame = try? await capturer.capture(.window(windowID)) else { break }
            frames.append(frame)

            // Stop if last two frames are identical (bottom reached)
            if frames.count >= 2 {
                let prev = frames[frames.count - 2]
                let curr = frames[frames.count - 1]
                if ImageStitcher.rowSignatures(prev) == ImageStitcher.rowSignatures(curr) { break }
            }

            // Post synthetic scroll-down event
            // ponytail: scrollWheelEvent2Source, units .line, negative = down
            let ev = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: Int32(-scrollLines), wheel2: 0, wheel3: 0)
            ev?.post(tap: .cghidEventTap)

            // Settle
            try? await Task.sleep(for: .milliseconds(150))
        }

        // 4. Stitch and present
        guard let tall = ImageStitcher.stitch(frames) else { return }
        await present(tall)
    }

    // MARK: - Private

    private func windowUnderCursor() async -> (CGWindowID, CGRect)? {
        guard let content = try? await SCShareableContent.current else { return nil }
        let cursor = NSEvent.mouseLocation
        // SCWindow.frame is top-left origin; flip to bottom-left global for hit-test
        let primaryHeight = NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height ?? NSScreen.main?.frame.height ?? 0
        for w in content.windows {
            guard w.isOnScreen, w.windowLayer == 0,
                  w.frame.width >= 40, w.frame.height >= 40 else { continue }
            let flipped = CGRect(
                x: w.frame.minX,
                y: primaryHeight - w.frame.minY - w.frame.height,
                width: w.frame.width,
                height: w.frame.height
            )
            if flipped.contains(cursor) {
                return (w.windowID, flipped)
            }
        }
        return nil
    }
}
