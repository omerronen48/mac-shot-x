import AppKit

// Floating pill shown during screen recording — click to stop.
@MainActor final class RecordStopPill: NSObject {

    private let panel: NSPanel
    private let button: NSButton

    var onStop: (() -> Void)?

    override init() {
        let pillSize = NSSize(width: 130, height: 36)

        // Build panel
        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: pillSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.ignoresMouseEvents = false

        // Single styled button acts as the entire pill
        button = NSButton(frame: NSRect(origin: .zero, size: pillSize))
        button.isBordered = false
        button.title = "● Stop  0:00"
        button.font = .systemFont(ofSize: 13, weight: .semibold)
        button.contentTintColor = .white

        // Dark capsule background via layer
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor(white: 0.1, alpha: 0.88).cgColor
        button.layer?.cornerRadius = pillSize.height / 2

        super.init()

        button.target = self
        button.action = #selector(stopTapped)

        let container = NSView(frame: NSRect(origin: .zero, size: pillSize))
        container.wantsLayer = true
        container.layer?.backgroundColor = .clear
        container.addSubview(button)
        panel.contentView = container
    }

    // MARK: - API

    func show(near rect: CGRect?) {
        let screen = screenFor(rect: rect) ?? NSScreen.main ?? NSScreen.screens[0]
        let visible = screen.visibleFrame
        let pw = panel.frame.width
        let ph = panel.frame.height
        let margin: CGFloat = 8

        var origin: NSPoint
        if let rect {
            // rect is display-local top-left points; convert to AppKit bottom-left
            // ponytail: simple top-center-of-screen fallback if rect mapping is unreliable
            let screenH = screen.frame.height
            // rect.maxY in top-left → AppKit bottom = screenH - rect.maxY
            let rectBottomInAppKit = screenH - rect.maxY
            let cx = screen.frame.minX + rect.midX
            origin = NSPoint(x: cx - pw / 2, y: rectBottomInAppKit + margin)
        } else {
            // Top-center of visible area, just below menu bar
            origin = NSPoint(
                x: visible.midX - pw / 2,
                y: visible.maxY - ph - margin
            )
        }

        // Clamp inside visibleFrame
        origin.x = max(visible.minX, min(origin.x, visible.maxX - pw))
        origin.y = max(visible.minY, min(origin.y, visible.maxY - ph))

        panel.setFrameOrigin(origin)
        panel.orderFront(nil)
    }

    func updateLabel(_ text: String) {
        button.title = text
    }

    func hide() {
        panel.orderOut(nil)
    }

    // MARK: - Private

    @objc private func stopTapped() {
        onStop?()
    }

    private func screenFor(rect: CGRect?) -> NSScreen? {
        guard let rect else { return nil }
        let midPoint = CGPoint(x: rect.midX, y: rect.midY)
        return NSScreen.screens.first { NSPointInRect(midPoint, $0.frame) }
    }
}
