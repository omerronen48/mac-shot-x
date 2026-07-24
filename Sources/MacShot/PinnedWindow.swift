import AppKit
import MacShotCore

// MARK: - Image view subclass so right-click context menu reaches NSPanel

private final class PinImageView: NSImageView {
    weak var panel: PinnedWindow?

    override func menu(for event: NSEvent) -> NSMenu? {
        panel?.pinMenu
    }
}

// MARK: - Pinned Window

@MainActor
final class PinnedWindow: NSPanel {

    private let storedImage: CGImage
    private var onCloseFired = false
    private let onClose: () -> Void
    fileprivate let pinMenu: NSMenu

    init(image: CGImage, frame: CGRect, onClose: @escaping () -> Void) {
        self.storedImage = image
        self.onClose = onClose

        // Build menu before super.init
        let menu = NSMenu()

        let opacityItem = NSMenuItem(title: "Opacity", action: nil, keyEquivalent: "")
        let opacitySub = NSMenu()
        for (label, value) in [("25%", 0.25), ("50%", 0.50), ("75%", 0.75), ("100%", 1.0)] {
            let item = NSMenuItem(title: label, action: #selector(PinnedWindow.opacityAction(_:)), keyEquivalent: "")
            item.tag = Int(value * 100)
            item.target = nil // resolved via responder chain to PinnedWindow
            opacitySub.addItem(item)
        }
        opacityItem.submenu = opacitySub
        menu.addItem(opacityItem)

        menu.addItem(NSMenuItem(title: "Copy", action: #selector(PinnedWindow.copyPin), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Close", action: #selector(PinnedWindow.closePin), keyEquivalent: ""))

        self.pinMenu = menu

        super.init(
            contentRect: frame,
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Floating, transparent chrome — draggable by background, resizable by corners
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isMovableByWindowBackground = true
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true

        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hasShadow = true
        isReleasedWhenClosed = false
        backgroundColor = .clear
        isFloatingPanel = true

        // Content
        let iv = PinImageView()
        iv.image = NSImage(cgImage: image, size: .zero)
        iv.imageScaling = .scaleProportionallyUpOrDown
        iv.autoresizingMask = [.width, .height]
        iv.panel = self
        contentView = iv

        // Wire menu item targets to self after init
        for item in opacitySub.items { item.target = self }
        for item in menu.items where item.submenu == nil { item.target = self }
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    // MARK: - Opacity

    func setOpacity(_ v: Double) {
        alphaValue = CGFloat(PinGeometry.clampOpacity(v))
    }

    @objc func opacityAction(_ sender: NSMenuItem) {
        setOpacity(Double(sender.tag) / 100.0)
    }

    // MARK: - Copy

    @objc func copyPin() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([NSImage(cgImage: storedImage, size: .zero)])
    }

    // MARK: - Close (fires onClose exactly once; PinController removes its ref)

    @objc func closePin() {
        guard !onCloseFired else { return }
        onCloseFired = true
        onClose()
        orderOut(nil)
    }
}
