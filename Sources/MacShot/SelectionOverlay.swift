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
        screenshot: CGImage? = nil,
        preferences: Preferences? = nil,
        completion: @escaping (CaptureMode?) -> Void
    ) {
        self.windows = windowList
        self.completion = completion

        for screen in NSScreen.screens {
            let ow = OverlayWindow(
                screen: screen,
                mode: mode,
                windowList: windowList,
                screenshot: screenshot,
                preferences: preferences
            ) { [weak self] result in
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
        screenshot: CGImage?,
        preferences: Preferences?,
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
            screenshot: screenshot,
            preferences: preferences,
            completion: completion
        )
        contentView = view
        makeFirstResponder(view)
    }

    // Borderless windows default canBecomeKey=false → keyDown never delivered.
    // Override so Esc (cancel) and Space (move) reach the overlay view.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Overlay NSView

@MainActor
private final class OverlayView: NSView {

    private let screen: NSScreen
    private let mode: CaptureMode
    private let windowList: [(CGWindowID, CGRect)]
    private let screenshot: CGImage?
    private let preferences: Preferences?
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
        screenshot: CGImage?,
        preferences: Preferences?,
        completion: @escaping (CaptureMode?) -> Void
    ) {
        self.screen = screen
        self.mode = mode
        self.windowList = windowList
        self.screenshot = screenshot
        self.preferences = preferences
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
        completion(.area(selectionRectInDisplayPoints(valid)))
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

        // 6. Magnifier loupe — only when a snapshot was provided and mode needs selection
        if let snap = screenshot, let prefs = preferences {
            switch mode {
            case .area, .window:
                drawLoupe(snap: snap, prefs: prefs, cursor: cursorPoint, in: ctx, bounds: b)
            case .fullscreen:
                break
            }
        }
    }

    // ponytail: samples ONLY the passed-in CGImage — never calls cacheDisplay/bitmapImageRepForCachingDisplay
    private func drawLoupe(snap: CGImage, prefs: Preferences, cursor: NSPoint, in ctx: CGContext, bounds: CGRect) {
        let scale = screen.backingScaleFactor
        let imgH = CGFloat(snap.height)

        // Cursor in snapshot pixel space: scale × Y-flip (view bottom-left → CGImage top-left)
        let pixelCursor = CGPoint(
            x: cursor.x * scale,
            y: imgH - cursor.y * scale   // flip Y
        )

        let loupeRect = LoupeGeometry.loupeRect(cursor: cursor, loupeSize: prefs.loupeSize, in: bounds)
        let sampleRect = LoupeGeometry.sampleRect(cursor: pixelCursor, magnification: prefs.loupeMagnification, loupeSize: prefs.loupeSize)

        guard let crop = snap.cropping(to: sampleRect) else { return }

        ctx.saveGState()
        // Clip to rounded rect
        let clipPath = NSBezierPath(roundedRect: loupeRect, xRadius: 8, yRadius: 8)
        ctx.addPath(clipPath.cgPath)
        ctx.clip()
        // Draw magnified crop — safe: no view-snapshot API involved
        ctx.draw(crop, in: loupeRect)
        ctx.restoreGState()

        // Outline
        if prefs.loupeOutlineEnabled {
            ctx.saveGState()
            let outlinePath = NSBezierPath(roundedRect: loupeRect, xRadius: 8, yRadius: 8)
            ctx.addPath(outlinePath.cgPath)
            ctx.setStrokeColor(prefs.loupeOutlineColor.cgColor)
            ctx.setLineWidth(1.5)
            ctx.strokePath()
            ctx.restoreGState()
        }
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

    // MARK: Coordinate conversion

    /// Convert the selection from overlay-local points (bottom-left origin) into the display's
    /// top-left-origin POINT space — what the capturer expects. The capturer scales points→pixels
    /// by the captured image's pixel/point ratio, so this stays Retina-correct. The overlay window
    /// fills its screen, so coordinates are already display-local (no global offset needed).
    private func selectionRectInDisplayPoints(_ viewRect: CGRect) -> CGRect {
        CGRect(
            x: viewRect.minX,
            y: screen.frame.height - viewRect.maxY,   // flip bottom-left → top-left
            width: viewRect.width,
            height: viewRect.height
        )
    }
}
