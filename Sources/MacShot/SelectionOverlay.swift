import AppKit
import MacShotCore

// ponytail: one file, thin AppKit renderer — all geometry math delegates to SelectionGeometry

@MainActor
public final class SelectionOverlay {

    private var windows: [(CGWindowID, CGRect)] = []
    private var completion: ((CaptureMode?) -> Void)?
    private var overlayWindows: [OverlayWindow] = []

    public init() {}

    public func present(
        mode: CaptureMode,
        windows windowList: [(CGWindowID, CGRect)],
        completion: @escaping (CaptureMode?) -> Void
    ) {
        self.windows = windowList
        self.completion = completion

        for screen in NSScreen.screens {
            let ow = OverlayWindow(screen: screen, mode: mode, windowList: windowList) { [weak self] result in
                self?.finish(result)
            }
            overlayWindows.append(ow)
            ow.makeKeyAndOrderFront(nil)
        }
    }

    private func finish(_ result: CaptureMode?) {
        for ow in overlayWindows { ow.orderOut(nil) }
        overlayWindows.removeAll()
        let cb = completion
        completion = nil
        cb?(result)
    }
}

// MARK: - Overlay NSWindow

@MainActor
private final class OverlayWindow: NSWindow {

    init(
        screen: NSScreen,
        mode: CaptureMode,
        windowList: [(CGWindowID, CGRect)],
        completion: @escaping (CaptureMode?) -> Void
    ) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = OverlayView(
            screen: screen,
            mode: mode,
            windowList: windowList,
            completion: completion
        )
        contentView = view
        makeFirstResponder(view)
    }
}

// MARK: - Overlay NSView

@MainActor
private final class OverlayView: NSView {

    private let screen: NSScreen
    private let mode: CaptureMode
    private let windowList: [(CGWindowID, CGRect)]
    private let completion: (CaptureMode?) -> Void

    // drag state
    private var dragStart: NSPoint?
    private var dragCurrent: NSPoint?
    private var isDragging = false
    private var isMoving = false          // Space held for reposition
    private var moveOffset: NSSize = .zero

    // window-mode state
    private var highlightedWindowID: CGWindowID?
    private var highlightedRect: CGRect?  // in view coords

    // cursor position (for crosshair / loupe)
    private var cursorPoint: NSPoint = .zero

    // ponytail: screenFrame in view coords = bounds (view fills screen frame)
    private var screenFrameInView: CGRect { bounds }

    init(
        screen: NSScreen,
        mode: CaptureMode,
        windowList: [(CGWindowID, CGRect)],
        completion: @escaping (CaptureMode?) -> Void
    ) {
        self.screen = screen
        self.mode = mode
        self.windowList = windowList
        self.completion = completion
        super.init(frame: .zero)
        // Track mouse moves for crosshair + window highlight
        let opts: NSTrackingArea.Options = [.activeAlways, .mouseMoved, .inVisibleRect]
        addTrackingArea(NSTrackingArea(rect: .zero, options: opts, owner: self, userInfo: nil))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: Key events

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: // Esc
            completion(nil)
        case 49 where !isMoving: // Space — start move-selection
            if let s = dragStart, let c = dragCurrent {
                let sel = SelectionGeometry.rect(from: s, to: c)
                let clamped = SelectionGeometry.clamp(sel, to: screenFrameInView)
                if SelectionGeometry.validated(clamped, minSide: 5) != nil {
                    isMoving = true
                    moveOffset = NSSize(
                        width: cursorPoint.x - clamped.midX,
                        height: cursorPoint.y - clamped.midY
                    )
                }
            }
        default:
            super.keyDown(with: event)
        }
    }

    override func keyUp(with event: NSEvent) {
        if event.keyCode == 49 { // Space released → confirm move
            isMoving = false
        }
        super.keyUp(with: event)
    }

    // MARK: Mouse events

    override func mouseDown(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        switch mode {
        case .area:
            dragStart = pt
            dragCurrent = pt
            isDragging = true
            needsDisplay = true
        case .window:
            if let id = highlightedWindowID {
                completion(.window(id))
            }
        case .fullscreen:
            break  // fullscreen shouldn't use overlay
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        cursorPoint = pt
        if isMoving, let s = dragStart, let c = dragCurrent {
            // Reposition the whole selection rectangle
            let sel = SelectionGeometry.rect(from: s, to: c)
            let clamped = SelectionGeometry.clamp(sel, to: screenFrameInView)
            let cx = pt.x - moveOffset.width
            let cy = pt.y - moveOffset.height
            let newOrigin = NSPoint(
                x: max(screenFrameInView.minX, min(cx - clamped.width / 2, screenFrameInView.maxX - clamped.width)),
                y: max(screenFrameInView.minY, min(cy - clamped.height / 2, screenFrameInView.maxY - clamped.height))
            )
            dragStart = newOrigin
            dragCurrent = NSPoint(x: newOrigin.x + clamped.width, y: newOrigin.y + clamped.height)
        } else {
            dragCurrent = pt
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard case .area = mode else { return }
        isDragging = false
        isMoving = false
        guard let s = dragStart, let c = dragCurrent else { completion(nil); return }
        let sel = SelectionGeometry.rect(from: s, to: c)
        let clamped = SelectionGeometry.clamp(sel, to: screenFrameInView)
        guard let valid = SelectionGeometry.validated(clamped, minSide: 5) else { completion(nil); return }
        completion(.area(viewRectToDisplayPixels(valid)))
    }

    override func mouseMoved(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        cursorPoint = pt
        if case .window = mode { updateWindowHighlight(at: pt) }
        needsDisplay = true
    }

    // MARK: Window highlight hit-test

    private func updateWindowHighlight(at pt: NSPoint) {
        // windowList rects are in screen (Cocoa flipped) coordinates → convert to view coords
        let screenOrigin = screen.frame.origin
        for (wid, screenRect) in windowList {
            // Convert from global screen coords to this view's coords
            let viewRect = CGRect(
                x: screenRect.origin.x - screenOrigin.x,
                y: screenRect.origin.y - screenOrigin.y,
                width: screenRect.width,
                height: screenRect.height
            )
            if viewRect.contains(pt) {
                highlightedWindowID = wid
                highlightedRect = viewRect
                return
            }
        }
        highlightedWindowID = nil
        highlightedRect = nil
    }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let b = bounds

        // 1. Dim fill
        ctx.setFillColor(NSColor(white: 0, alpha: 0.25).cgColor)
        ctx.fill(b)

        if case .area = mode, let s = dragStart, let c = dragCurrent {
            let sel = SelectionGeometry.rect(from: s, to: c)
            let clamped = SelectionGeometry.clamp(sel, to: screenFrameInView)
            if let valid = SelectionGeometry.validated(clamped, minSide: 1) {
                // 2. Clear "hole" — remove dim
                ctx.clear(valid)

                // 3. 1px selection border
                ctx.setStrokeColor(NSColor.white.cgColor)
                ctx.setLineWidth(1)
                ctx.stroke(valid)

                // 4. Dimension readout near cursor
                let label = String(format: "%.0f × %.0f", valid.width * screen.backingScaleFactor, valid.height * screen.backingScaleFactor)
                drawLabel(label, near: cursorPoint, in: ctx)
            }
        }

        if case .window = mode, let rect = highlightedRect {
            // Window highlight — tinted border
            ctx.setStrokeColor(NSColor.systemBlue.withAlphaComponent(0.9).cgColor)
            ctx.setLineWidth(3)
            ctx.stroke(rect)
            ctx.setFillColor(NSColor.systemBlue.withAlphaComponent(0.08).cgColor)
            ctx.fill(rect)
        }

        // 5. Crosshair at cursor
        drawCrosshair(at: cursorPoint, in: ctx, bounds: b)

        // 6. Magnifier loupe near cursor
        drawLoupe(at: cursorPoint, in: ctx)
    }

    private func drawCrosshair(at pt: NSPoint, in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.white.cgColor)
        ctx.setLineWidth(0.5)
        ctx.setAlpha(0.6)
        ctx.move(to: CGPoint(x: pt.x, y: bounds.minY))
        ctx.addLine(to: CGPoint(x: pt.x, y: bounds.maxY))
        ctx.move(to: CGPoint(x: bounds.minX, y: pt.y))
        ctx.addLine(to: CGPoint(x: bounds.maxX, y: pt.y))
        ctx.strokePath()
        ctx.restoreGState()
    }

    private func drawLabel(_ text: String, near pt: NSPoint, in ctx: CGContext) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let size = str.size()
        let pad: CGFloat = 6
        let boxW = size.width + pad * 2
        let boxH = size.height + pad
        let offsetX: CGFloat = 16, offsetY: CGFloat = 16
        var ox = pt.x + offsetX
        var oy = pt.y + offsetY
        // Clamp to view
        if ox + boxW > bounds.maxX { ox = pt.x - offsetX - boxW }
        if oy + boxH > bounds.maxY { oy = pt.y - offsetY - boxH }

        let box = CGRect(x: ox, y: oy, width: boxW, height: boxH)
        ctx.setFillColor(NSColor(white: 0, alpha: 0.6).cgColor)
        ctx.fill(box)

        // Draw attributed string via NSGraphicsContext — we're inside draw(_:) so it's fine
        str.draw(at: NSPoint(x: ox + pad, y: oy + pad / 2))
    }

    // ponytail: loupe = simple NSImage snapshot of the area + draw scaled — no pixel-perfect requirement
    private func drawLoupe(at pt: NSPoint, in ctx: CGContext) {
        let loupeSize: CGFloat = 80
        let zoom: CGFloat = 4
        let sampleSize: CGFloat = loupeSize / zoom
        let sampleRect = CGRect(
            x: pt.x - sampleSize / 2,
            y: pt.y - sampleSize / 2,
            width: sampleSize,
            height: sampleSize
        ).intersection(bounds)
        guard !sampleRect.isEmpty, sampleRect.width > 2, sampleRect.height > 2 else { return }

        // Position loupe away from cursor
        let lx = pt.x + 24
        let ly = pt.y + 24
        guard lx + loupeSize < bounds.maxX, ly + loupeSize < bounds.maxY else { return }
        let loupeRect = CGRect(x: lx, y: ly, width: loupeSize, height: loupeSize)

        // Capture the window's current backing image for the sample area
        guard let bitmapRep = bitmapImageRepForCachingDisplay(in: sampleRect) else { return }
        cacheDisplay(in: sampleRect, to: bitmapRep)
        guard let cgImage = bitmapRep.cgImage else { return }

        ctx.saveGState()
        // Circular clip for the loupe
        ctx.addEllipse(in: loupeRect)
        ctx.clip()
        // Draw zoomed image
        ctx.draw(cgImage, in: loupeRect)
        ctx.restoreGState()

        // Loupe border
        ctx.setStrokeColor(NSColor.white.cgColor)
        ctx.setLineWidth(1.5)
        ctx.addEllipse(in: loupeRect)
        ctx.strokePath()
    }

    // MARK: Coordinate conversion

    private func viewRectToDisplayPixels(_ viewRect: CGRect) -> CGRect {
        // viewRect is in view/window coords (origin at screen.frame.origin in flipped global space)
        let scale = screen.backingScaleFactor
        let sOrigin = screen.frame.origin
        return CGRect(
            x: (viewRect.origin.x + sOrigin.x) * scale,
            y: (viewRect.origin.y + sOrigin.y) * scale,
            width: viewRect.width * scale,
            height: viewRect.height * scale
        )
    }
}
