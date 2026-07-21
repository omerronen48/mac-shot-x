import AppKit
import MacShotCore
import UniformTypeIdentifiers

// ponytail: one controller, plain Timer, no Combine, no animation

@MainActor
public final class OverlayController {

    private var stack = OverlayStack(expiry: 8, visibleCap: 5)
    private var panels: [Int: QuickAccessPanel] = [:]
    private var nextID: Int = 0
    private let historyStore: HistoryStore
    private var timer: Timer?

    private let panelHeight: CGFloat = 180
    private let gap: CGFloat = 8
    private let edgeMargin: CGFloat = 16

    /// Set by AppDelegate to open the annotation editor for a captured image.
    public var onEdit: ((CGImage) -> Void)?
    public var onHistory: (() -> Void)?

    public init(historyStore: HistoryStore) {
        self.historyStore = historyStore
    }

    // MARK: - Present

    public func present(_ result: CaptureResult) {
        let id = nextID
        nextID += 1

        stack.push(id: id, at: Date())

        let panel = QuickAccessPanel(result: result)

        panel.onHoverChanged = { [weak self] inside in
            guard let self else { return }
            if inside {
                self.stack.keepAlive(id: id)
            } else {
                self.stack.release(id: id, at: Date())
                self.reflow()
            }
        }

        panel.onAction = { [weak self] action in
            self?.handle(action: action, id: id, result: result)
        }

        panels[id] = panel
        reflow()
        panel.orderFront(nil)
        ensureTimer()
    }

    // MARK: - Reflow

    func reflow() {
        let visible = stack.visible(at: Date())
        let visibleIDs = Set(visible.map(\.id))

        // Position on the screen under the cursor (where the capture happened), clamped fully
        // inside its visibleFrame so nothing is hidden behind a screen edge or the Dock.
        // NSScreen.main can be nil for a menu-bar accessory app, and the old 1440x900 fallback
        // pushed the panel off narrow displays — clamp against the panel's real size instead.
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
            ?? NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        // Force a CONSTANT panel size every tick so nothing (image intrinsic size, layout) can
        // grow it — this snaps back any drift that caused the "resize/jump" on large captures.
        let size = NSSize(width: 224, height: panelHeight)
        for slot in visible {
            guard let panel = panels[slot.id] else { continue }
            var x = frame.maxX - size.width - edgeMargin
            var y = frame.minY + edgeMargin + CGFloat(slot.index) * (panelHeight + gap)
            x = max(frame.minX + edgeMargin, min(x, frame.maxX - size.width - edgeMargin))
            y = max(frame.minY + edgeMargin, min(y, frame.maxY - size.height - edgeMargin))
            panel.setFrame(NSRect(origin: NSPoint(x: x, y: y), size: size), display: true)
            if !panel.isVisible { panel.orderFront(nil) }
        }

        // close expired panels
        for (id, panel) in panels where !visibleIDs.contains(id) {
            panel.close()
            panels.removeValue(forKey: id)
        }

        if panels.isEmpty { invalidateTimer() }
    }

    // MARK: - Timer

    private func ensureTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            // Timer fires on the main run loop — safe to assume main actor isolation
            MainActor.assumeIsolated { self?.reflow() }
        }
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Action handler

    private func handle(action: PanelAction, id: Int, result: CaptureResult) {
        switch action {
        case .copy:
            let img = NSImage(cgImage: result.image, size: result.size)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([img])

        case .saveAs:
            if let url = result.fileURL {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            } else {
                let save = NSSavePanel()
                save.allowedContentTypes = [.png]
                save.nameFieldStringValue = "screenshot.png"
                save.begin { [result] response in
                    guard response == .OK, let dest = save.url else { return }
                    writePNG(result.image, to: dest)
                }
            }

        case .delete:
            if let url = result.fileURL {
                let entry = HistoryEntry(url: url, filename: url.lastPathComponent,
                                        captureDate: Date(), isPinned: false)
                try? historyStore.delete(entry)
            }
            stack.dismiss(id: id)
            reflow()

        case .pin:
            if let url = result.fileURL {
                let entry = HistoryEntry(url: url, filename: url.lastPathComponent,
                                        captureDate: Date(), isPinned: false)
                historyStore.pin(entry)
            }

        case .dragStarted:
            break // handled inside QuickAccessPanel
        case .edit:
            onEdit?(result.image)
        case .history:
            onHistory?()
        }
    }
}

// MARK: - PNG helper

private func writePNG(_ image: CGImage, to url: URL) {
    guard let dest = CGImageDestinationCreateWithURL(
        url as CFURL, UTType.png.identifier as CFString, 1, nil
    ) else { return }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}
