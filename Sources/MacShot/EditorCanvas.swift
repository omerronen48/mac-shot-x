import SwiftUI
import AppKit
import MacShotCore

// MARK: - Tool

enum Tool {
    case select, arrow, rectangle, ellipse, text, highlighter, blur, step, line, solidCensor, emoji
}

// MARK: - ViewModel

@Observable
@MainActor
final class EditorViewModel {
    var document: AnnotationDocument
    var undo: UndoStack
    var activeTool: Tool = .select
    var style: AnnotationStyle = .default
    var selection: UUID?
    var beautifyStyle: BeautifyStyle = .none
    let presetStore: PresetStore

    private(set) var inProgressID: UUID?
    private var dragStart: CGPoint?

    init(document: AnnotationDocument,
         presetStore: PresetStore = PresetStore(store: UserDefaults.standard)) {
        self.document = document
        self.undo = UndoStack(initial: document.annotations)
        self.presetStore = presetStore
    }

    func beginStroke(at point: CGPoint) {
        undo.record(current: document.annotations)
        dragStart = point
        switch activeTool {
        case .select:
            selection = document.hitTest(point)
        case .arrow:
            let a = Annotation(kind: .arrow(from: point, to: point), style: style)
            document.add(a); inProgressID = a.id
        case .rectangle:
            let a = Annotation(kind: .rectangle(CGRect(origin: point, size: .zero)), style: style)
            document.add(a); inProgressID = a.id
        case .ellipse:
            let a = Annotation(kind: .ellipse(CGRect(origin: point, size: .zero)), style: style)
            document.add(a); inProgressID = a.id
        case .highlighter:
            let a = Annotation(kind: .highlighter(CGRect(origin: point, size: .zero)), style: style)
            document.add(a); inProgressID = a.id
        case .blur:
            let a = Annotation(kind: .blur(CGRect(origin: point, size: .zero), radius: 10, pixelate: false), style: style)
            document.add(a); inProgressID = a.id
        case .step:
            let a = Annotation(kind: .stepNumber(center: point, number: document.nextStepNumber), style: style)
            document.add(a); inProgressID = a.id
        case .text:
            // text is committed via commitText(_:in:); no in-progress stroke
            break
        case .line:
            let a = Annotation(kind: .line(from: point, to: point), style: style)
            document.add(a); inProgressID = a.id
        case .solidCensor:
            let a = Annotation(kind: .solidCensor(CGRect(origin: point, size: .zero)), style: style)
            document.add(a); inProgressID = a.id
        case .emoji:
            // ponytail: place a placeholder emoji, then open the system character palette;
            // the hidden NSTextField responder captures the chosen character and updates
            // the annotation. Ceiling: palette sends characters to the focused input, not to
            // arbitrary callbacks — a proper integration would use NSTextInputClient.
            let a = Annotation(kind: .emoji(center: point, string: "", size: style.fontSize * 2), style: style)
            document.add(a); inProgressID = a.id
        }
    }

    func updateStroke(to point: CGPoint) {
        guard let start = dragStart else { return }
        switch activeTool {
        case .select:
            guard let id = selection else { return }
            let delta = CGPoint(x: point.x - start.x, y: point.y - start.y)
            document.update(id: id) { a in
                switch a.kind {
                case let .arrow(from, to):
                    a.kind = .arrow(from: CGPoint(x: from.x + delta.x, y: from.y + delta.y),
                                     to: CGPoint(x: to.x + delta.x, y: to.y + delta.y))
                case let .rectangle(r):   a.kind = .rectangle(r.offsetBy(dx: delta.x, dy: delta.y))
                case let .ellipse(r):     a.kind = .ellipse(r.offsetBy(dx: delta.x, dy: delta.y))
                case let .text(r, s):     a.kind = .text(r.offsetBy(dx: delta.x, dy: delta.y), s)
                case let .highlighter(r): a.kind = .highlighter(r.offsetBy(dx: delta.x, dy: delta.y))
                case let .blur(r, rad, px): a.kind = .blur(r.offsetBy(dx: delta.x, dy: delta.y), radius: rad, pixelate: px)
                case let .stepNumber(c, n):
                    a.kind = .stepNumber(center: CGPoint(x: c.x + delta.x, y: c.y + delta.y), number: n)
                case let .line(from, to):
                    a.kind = .line(from: CGPoint(x: from.x + delta.x, y: from.y + delta.y),
                                   to: CGPoint(x: to.x + delta.x, y: to.y + delta.y))
                case let .solidCensor(r): a.kind = .solidCensor(r.offsetBy(dx: delta.x, dy: delta.y))
                case let .emoji(c, s, size):
                    a.kind = .emoji(center: CGPoint(x: c.x + delta.x, y: c.y + delta.y), string: s, size: size)
                }
            }
            dragStart = point  // incremental delta
        case .arrow:
            guard let id = inProgressID else { return }
            document.update(id: id) { a in a.kind = .arrow(from: start, to: point) }
        case .rectangle:
            guard let id = inProgressID else { return }
            document.update(id: id) { a in a.kind = .rectangle(rect(from: start, to: point)) }
        case .ellipse:
            guard let id = inProgressID else { return }
            document.update(id: id) { a in a.kind = .ellipse(rect(from: start, to: point)) }
        case .highlighter:
            guard let id = inProgressID else { return }
            document.update(id: id) { a in a.kind = .highlighter(rect(from: start, to: point)) }
        case .blur:
            guard let id = inProgressID else { return }
            document.update(id: id) { a in a.kind = .blur(rect(from: start, to: point), radius: 10, pixelate: false) }
        case .step, .text, .emoji:
            break
        case .line:
            guard let id = inProgressID else { return }
            document.update(id: id) { a in a.kind = .line(from: start, to: point) }
        case .solidCensor:
            guard let id = inProgressID else { return }
            document.update(id: id) { a in a.kind = .solidCensor(rect(from: start, to: point)) }
        }
    }

    func endStroke() {
        inProgressID = nil
        dragStart = nil
    }

    func commitText(_ string: String, in rect: CGRect) {
        guard !string.isEmpty else { return }
        undo.record(current: document.annotations)
        document.add(Annotation(kind: .text(rect, string), style: style))
    }

    func delete(id: UUID) {
        undo.record(current: document.annotations)
        document.remove(id: id)
        if selection == id { selection = nil }
    }

    func undoAction() { document.setAll(undo.undo(current: document.annotations)) }
    func redoAction() { document.setAll(undo.redo(current: document.annotations)) }
    func nextStep() -> Int { document.nextStepNumber }

    private func rect(from a: CGPoint, to b: CGPoint) -> CGRect {
        CGRect(x: min(a.x, b.x), y: min(a.y, b.y),
               width: abs(b.x - a.x), height: abs(b.y - a.y))
    }
}

// MARK: - Canvas

struct EditorCanvas: View {
    let vm: EditorViewModel
    let base: CGImage

    @State private var textInput: String = ""
    @State private var textRect: CGRect? = nil
    @State private var emojiPickerActive = false

    var body: some View {
        GeometryReader { geo in
            let scale = fitScale(geo.size)
            let offset = fitOffset(geo.size, scale: scale)

            ZStack(alignment: .topLeading) {
                // Live beautify frame: background + shadow behind the canvas.
                // ponytail: corner-clip of the image is NOT applied live (clipping the Canvas
                // would also clip annotations); exact clip is applied at export by BeautifyRenderer.
                BeautifyFrameView(style: vm.beautifyStyle, imgRect: CGRect(
                    x: offset.x, y: offset.y,
                    width: CGFloat(base.width) * scale,
                    height: CGFloat(base.height) * scale
                ))

                Canvas { ctx, size in
                    // Draw base image
                    let imgRect = CGRect(
                        x: offset.x, y: offset.y,
                        width: CGFloat(base.width) * scale,
                        height: CGFloat(base.height) * scale
                    )
                    ctx.draw(Image(decorative: base, scale: 1, orientation: .up), in: imgRect)

                    // Draw annotations
                    for ann in vm.document.annotations {
                        drawAnnotation(ann, ctx: &ctx, scale: scale, offset: offset)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            let pt = toImage(val.location, scale: scale, offset: offset)
                            if val.startLocation == val.location {
                                vm.beginStroke(at: pt)
                                if vm.activeTool == .text {
                                    textRect = CGRect(origin: pt, size: CGSize(width: 200, height: 40))
                                    textInput = ""
                                }
                                if vm.activeTool == .emoji {
                                    emojiPickerActive = true
                                }
                            } else {
                                vm.updateStroke(to: pt)
                            }
                        }
                        .onEnded { val in
                            vm.endStroke()
                        }
                )

                // Text overlay
                if let tr = textRect, vm.activeTool == .text {
                    let viewPt = toView(tr.origin, scale: scale, offset: offset)
                    TextField("Text", text: $textInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: vm.style.fontSize))
                        .foregroundColor(Color(cgColor: vm.style.strokeColor.cgColor))
                        .frame(width: 200)
                        .background(Color.black.opacity(0.15))
                        .offset(x: viewPt.x, y: viewPt.y)
                        .onSubmit {
                            if let r = textRect {
                                vm.commitText(textInput, in: r)
                            }
                            textRect = nil
                            textInput = ""
                        }
                }

                // Emoji picker: hidden NSTextField becomes first responder so the system
                // character palette can route its output to it.
                // ponytail: ceiling is that NSApp.orderFrontCharacterPalette sends characters
                // to the focused NSTextView; if the palette fires without focus we miss it.
                // Upgrade path: implement NSTextInputClient on a custom NSView.
                if emojiPickerActive, let eid = vm.inProgressID {
                    EmojiCaptureField { str in
                        if str.isEmpty {
                            vm.document.remove(id: eid)
                        } else {
                            vm.document.update(id: eid) { a in
                                if case let .emoji(c, _, sz) = a.kind {
                                    a.kind = .emoji(center: c, string: str, size: sz)
                                }
                            }
                        }
                        emojiPickerActive = false
                        vm.endStroke()
                    }
                    .frame(width: 1, height: 1)
                    .opacity(0)
                }
            }
        }
    }

    // MARK: - Coordinate helpers

    private func fitScale(_ viewSize: CGSize) -> CGFloat {
        min(viewSize.width / CGFloat(base.width), viewSize.height / CGFloat(base.height))
    }

    private func fitOffset(_ viewSize: CGSize, scale: CGFloat) -> CGPoint {
        CGPoint(
            x: (viewSize.width  - CGFloat(base.width)  * scale) / 2,
            y: (viewSize.height - CGFloat(base.height) * scale) / 2
        )
    }

    /// SwiftUI view point → image pixel coords (y flipped: SwiftUI top-left, image bottom-left)
    private func toImage(_ pt: CGPoint, scale: CGFloat, offset: CGPoint) -> CGPoint {
        let ix = (pt.x - offset.x) / scale
        let iy = CGFloat(base.height) - (pt.y - offset.y) / scale
        return CGPoint(x: ix, y: iy)
    }

    /// Image pixel coords → SwiftUI view point
    private func toView(_ pt: CGPoint, scale: CGFloat, offset: CGPoint) -> CGPoint {
        let vx = pt.x * scale + offset.x
        let vy = (CGFloat(base.height) - pt.y) * scale + offset.y
        return CGPoint(x: vx, y: vy)
    }

    // MARK: - Per-annotation drawing

    private func drawAnnotation(_ ann: Annotation, ctx: inout GraphicsContext, scale: CGFloat, offset: CGPoint) {
        let stroke = Color(cgColor: ann.style.strokeColor.cgColor)
        let lw = ann.style.lineWidth * scale

        func vr(_ r: CGRect) -> CGRect {
            // image rect → view rect (y-flip)
            let minY = CGFloat(base.height) - r.maxY
            return CGRect(
                x: r.minX * scale + offset.x,
                y: minY  * scale + offset.y,
                width: r.width  * scale,
                height: r.height * scale
            )
        }
        func vp(_ p: CGPoint) -> CGPoint {
            toView(p, scale: scale, offset: offset)
        }

        switch ann.kind {
        case let .rectangle(r):
            let vRect = vr(r)
            if let fc = ann.style.fillColor {
                ctx.fill(Path(vRect), with: .color(Color(cgColor: fc.cgColor)))
            }
            ctx.stroke(Path(vRect), with: .color(stroke), lineWidth: lw)

        case let .ellipse(r):
            let vRect = vr(r)
            if let fc = ann.style.fillColor {
                ctx.fill(Path(ellipseIn: vRect), with: .color(Color(cgColor: fc.cgColor)))
            }
            ctx.stroke(Path(ellipseIn: vRect), with: .color(stroke), lineWidth: lw)

        case let .arrow(from, to):
            let vFrom = vp(from), vTo = vp(to)
            var path = Path()
            path.move(to: vFrom); path.addLine(to: vTo)
            let angle = atan2(vTo.y - vFrom.y, vTo.x - vFrom.x)
            let head = max(10, lw * 4)
            path.move(to: vTo)
            path.addLine(to: CGPoint(x: vTo.x - head * cos(angle - .pi/6),
                                      y: vTo.y - head * sin(angle - .pi/6)))
            path.move(to: vTo)
            path.addLine(to: CGPoint(x: vTo.x - head * cos(angle + .pi/6),
                                      y: vTo.y - head * sin(angle + .pi/6)))
            ctx.stroke(path, with: .color(stroke), lineWidth: lw)

        case let .highlighter(r):
            // ponytail: multiply blend not exposed in SwiftUI GraphicsContext; use 40% opacity fill
            ctx.fill(Path(vr(r)), with: .color(stroke.opacity(0.4)))

        case let .text(r, s):
            let vRect = vr(r)
            ctx.draw(Text(s).font(.system(size: ann.style.fontSize * scale)).foregroundColor(stroke),
                     at: CGPoint(x: vRect.minX, y: vRect.midY), anchor: .leading)

        case let .blur(r, _, _):
            // ponytail: live blur is a placeholder; true blur applied by AnnotationRenderer at export
            ctx.fill(Path(vr(r)), with: .color(.gray.opacity(0.4)))

        case let .stepNumber(c, n):
            let vc = vp(c)
            let d = 32.0 * scale
            let circleRect = CGRect(x: vc.x - d/2, y: vc.y - d/2, width: d, height: d)
            ctx.fill(Path(ellipseIn: circleRect), with: .color(stroke))
            ctx.draw(
                Text("\(n)").font(.system(size: 18 * scale, weight: .bold)).foregroundColor(.white),
                at: vc, anchor: .center
            )

        case let .line(from, to):
            var p = Path(); p.move(to: vp(from)); p.addLine(to: vp(to))
            ctx.stroke(p, with: .color(stroke), lineWidth: lw)

        case let .solidCensor(r):
            ctx.fill(Path(vr(r)), with: .color(stroke))

        case let .emoji(c, s, size):
            ctx.draw(Text(s).font(.system(size: size * scale)), at: vp(c), anchor: .center)
        }

        // Selection highlight
        if vm.selection == ann.id {
            let bb: CGRect
            switch ann.kind {
            case let .arrow(from, to):
                let vFrom = vp(from), vTo = vp(to)
                bb = CGRect(x: min(vFrom.x, vTo.x) - 4, y: min(vFrom.y, vTo.y) - 4,
                            width: abs(vFrom.x - vTo.x) + 8, height: abs(vFrom.y - vTo.y) + 8)
            default:
                bb = vr(ann.boundingBox).insetBy(dx: -4, dy: -4)
            }
            ctx.stroke(Path(bb), with: .color(.accentColor.opacity(0.8)), style: StrokeStyle(lineWidth: 2, dash: [6, 3]))
        }
    }
}

// MARK: - BeautifyFrameView

/// Renders the beautify background + shadow behind the canvas image.
/// Positioned and sized to the padded rect around `imgRect`.
/// ponytail: corner-clip on the image is skipped live (export-only via BeautifyRenderer).
private struct BeautifyFrameView: View {
    let style: BeautifyStyle
    let imgRect: CGRect

    var body: some View {
        let pad = style.padding
        // .none: zero padding + no shadow → nothing to show.
        if pad == 0 && style.shadow == nil { return AnyView(EmptyView()) }

        let frameRect = imgRect.insetBy(dx: -pad, dy: -pad)
        let bg = resolvedBackground(style.background)

        let base = Rectangle()
            .fill(AnyShapeStyle(bg))
            .frame(width: frameRect.width, height: frameRect.height)
            .offset(x: frameRect.minX, y: frameRect.minY)

        if let sh = style.shadow {
            return AnyView(
                base.shadow(
                    color: Color(cgColor: sh.color.cgColor).opacity(sh.opacity),
                    radius: sh.radius,
                    x: sh.offset.width,
                    y: sh.offset.height
                )
            )
        }
        return AnyView(base)
    }

    /// Maps BeautifyBackground to an AnyShapeStyle for use in .fill().
    /// ponytail: gradient angle uses CSS convention (0° = top→bottom, CW);
    /// mapped via sin/cos — angle 135° → topLeading→bottomTrailing (matches builtins).
    private func resolvedBackground(_ bg: BeautifyBackground) -> AnyShapeStyle {
        switch bg {
        case let .solid(c):
            return AnyShapeStyle(Color(cgColor: c.cgColor))
        case let .linearGradient(colors, angle):
            let a = angle * .pi / 180
            let start = UnitPoint(x: 0.5 - 0.5 * sin(a), y: 0.5 - 0.5 * cos(a))
            let end   = UnitPoint(x: 0.5 + 0.5 * sin(a), y: 0.5 + 0.5 * cos(a))
            return AnyShapeStyle(LinearGradient(
                colors: colors.map { Color(cgColor: $0.cgColor) },
                startPoint: start, endPoint: end
            ))
        case let .image(path):
            // ponytail: fallback to gray if image file is missing
            if let img = NSImage(contentsOfFile: path) {
                return AnyShapeStyle(ImagePaint(image: Image(nsImage: img)))
            }
            return AnyShapeStyle(Color(white: 0.5))
        }
    }
}

// MARK: - Emoji capture field

/// Hidden NSTextField that becomes first responder, opens the system character palette,
/// and fires `onCommit` with the first character typed (typically from the palette).
/// ponytail: uses NSTextField as the input sink; the palette routes input to the focused
/// text field. Ceiling: only captures characters typed/inserted while this field is focused;
/// the palette dismissal is not observed directly. Upgrade: NSTextInputClient custom view.
private struct EmojiCaptureField: NSViewRepresentable {
    let onCommit: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCommit: onCommit) }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.isHidden = false
        field.delegate = context.coordinator
        DispatchQueue.main.async {
            field.window?.makeFirstResponder(field)
            NSApp.orderFrontCharacterPalette(nil)
        }
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {}

    class Coordinator: NSObject, NSTextFieldDelegate {
        let onCommit: (String) -> Void
        init(onCommit: @escaping (String) -> Void) { self.onCommit = onCommit }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            let text = field.stringValue
            guard !text.isEmpty else { return }
            // Take first composed sequence (emoji may be multi-scalar)
            onCommit(String(text.unicodeScalars.prefix(2).map(Character.init)))
        }
    }
}
