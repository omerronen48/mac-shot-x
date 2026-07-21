import AppKit
import MacShotCore
import UniformTypeIdentifiers

// ponytail: pure AppKit — NSPanel + NSView + NSStackView; no SwiftUI overhead for a throwaway floating panel

// MARK: - Action enum (T7 references this)

public enum PanelAction {
    case copy, saveAs, delete, pin, dragStarted
}

// MARK: - Public panel

@MainActor
public final class QuickAccessPanel: NSPanel {

    public var onHoverChanged: (Bool) -> Void = { _ in }
    public var onAction: (PanelAction) -> Void = { _ in }

    private let result: CaptureResult
    private var isPinned: Bool = false

    public init(result: CaptureResult) {
        self.result = result
        // ponytail: .titled omitted — borderless clears chrome; nonactivatingPanel keeps focus elsewhere
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 224, height: 180),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .floating
        isFloatingPanel = true
        hidesOnDeactivate = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true

        let content = PanelContentView(result: result)
        content.onHoverChanged = { [weak self] inside in self?.onHoverChanged(inside) }
        content.onAction = { [weak self] action in
            if case .pin = action { self?.isPinned.toggle() }
            self?.onAction(action)
        }
        contentView = content
    }
}

// MARK: - Content view

@MainActor
private final class PanelContentView: NSView {

    var onHoverChanged: (Bool) -> Void = { _ in }
    var onAction: (PanelAction) -> Void = { _ in }

    private let result: CaptureResult

    init(result: CaptureResult) {
        self.result = result
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor(white: 0.12, alpha: 0.92).cgColor

        let imageView = DraggableImageView(result: result)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.onDragStarted = { [weak self] in self?.onAction(.dragStarted) }
        addSubview(imageView)

        let buttons = makeButtonRow()
        buttons.translatesAutoresizingMaskIntoConstraints = false
        addSubview(buttons)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            imageView.heightAnchor.constraint(equalToConstant: 120),

            buttons.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
            buttons.centerXAnchor.constraint(equalTo: centerXAnchor),
            buttons.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])

        // Hover tracking on whole view
        let opts: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        addTrackingArea(NSTrackingArea(rect: .zero, options: opts, owner: self, userInfo: nil))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: Hover

    override func mouseEntered(with event: NSEvent) { onHoverChanged(true) }
    override func mouseExited(with event: NSEvent)  { onHoverChanged(false) }

    // MARK: Button row

    private func makeButtonRow() -> NSStackView {
        let hasDisk = result.fileURL != nil

        let copyBtn   = makeButton("doc.on.doc",   tip: "Copy",     action: #selector(tapCopy))
        let saveBtn   = makeButton(hasDisk ? "folder" : "square.and.arrow.down",
                                   tip: hasDisk ? "Reveal in Finder" : "Save As…",
                                   action: #selector(tapSave))
        let deleteBtn = makeButton("trash",        tip: "Delete",   action: #selector(tapDelete))
        let pinBtn    = makeButton("pin",           tip: "Pin",      action: #selector(tapPin))

        if !hasDisk { deleteBtn.isEnabled = false }  // nothing on disk

        let stack = NSStackView(views: [copyBtn, saveBtn, deleteBtn, pinBtn])
        stack.orientation = .horizontal
        stack.spacing = 8
        return stack
    }

    private func makeButton(_ symbol: String, tip: String, action: Selector) -> NSButton {
        let btn = NSButton()
        btn.bezelStyle = .regularSquare
        btn.isBordered = false
        btn.image = NSImage(systemSymbolName: symbol, accessibilityDescription: tip)
        btn.image?.isTemplate = true
        btn.contentTintColor = .white
        btn.toolTip = tip
        btn.target = self
        btn.action = action
        btn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btn.widthAnchor.constraint(equalToConstant: 28),
            btn.heightAnchor.constraint(equalToConstant: 28),
        ])
        return btn
    }

    @objc private func tapCopy()   { onAction(.copy) }
    @objc private func tapSave()   { onAction(.saveAs) }
    @objc private func tapDelete() { onAction(.delete) }
    @objc private func tapPin()    { onAction(.pin) }
}

// MARK: - Draggable image view

@MainActor
private final class DraggableImageView: NSImageView, NSDraggingSource {

    var onDragStarted: () -> Void = {}
    private let result: CaptureResult

    init(result: CaptureResult) {
        self.result = result
        super.init(frame: .zero)
        let nsImage = NSImage(cgImage: result.image, size: result.size)
        self.image = nsImage
        imageScaling = .scaleProportionallyUpOrDown
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.masksToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: NSDraggingSource

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        .copy
    }

    override func mouseDragged(with event: NSEvent) {
        let url = dragURL()
        let item = NSPasteboardItem()
        item.setString(url.absoluteString, forType: .fileURL)

        let draggingItem = NSDraggingItem(pasteboardWriter: item)
        draggingItem.setDraggingFrame(bounds, contents: image)

        onDragStarted()
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }

    // ponytail: writes temp PNG only when fileURL is absent; caller never sees the path
    private func dragURL() -> URL {
        if let url = result.fileURL { return url }
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("macshot-drag-\(UUID().uuidString).png")
        writePNG(result.image, to: tmp)
        return tmp
    }

    private func writePNG(_ image: CGImage, to url: URL) {
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { return }
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
    }
}
