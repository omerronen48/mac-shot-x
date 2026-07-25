import AppKit
import SwiftUI
import MacShotCore

/// Hosts the annotation editor in an NSWindow. Export writes a flattened PNG + copies to
/// clipboard; closing the window auto-copies the annotated result to the clipboard.
@MainActor
final class EditorWindow: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let sink: SystemSink
    private let preferences: Preferences
    private let base: CGImage
    private let vm: EditorViewModel
    private var didCopyOnExport = false
    /// Fired on close so the owner can release this instance (avoids retaining every editor).
    var onClose: (() -> Void)?

    init(base: CGImage, sink: SystemSink, preferences: Preferences) {
        self.sink = sink
        self.preferences = preferences
        self.base = base

        let doc = AnnotationDocument(baseSize: CGSize(width: base.width, height: base.height))
        let vm = EditorViewModel(document: doc)
        self.vm = vm
        super.init()

        let onExport: () -> Void = { [weak self] in
            guard let self else { return }
            let out = self.flattened()
            self.sink.copyToClipboard(out)
            self.didCopyOnExport = true
            let dir = URL(fileURLWithPath: self.preferences.saveDirectoryPath, isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let formatter = FilenameFormatter(format: self.preferences.filenameFormat)
            let name = formatter.uniqueFilename(for: Date(), mode: "beautified") {
                FileManager.default.fileExists(atPath: dir.appendingPathComponent($0).path)
            }
            do {
                _ = try self.sink.writePNG(out, suggestedName: name, inDirectory: dir)
            } catch {
                let a = NSAlert()
                a.messageText = "Couldn’t save the exported image"
                a.informativeText = "Check your save folder in Preferences — it was still copied to the clipboard."
                a.runModal()
            }
            self.window?.close()
        }

        let root = VStack(spacing: 0) {
            ToolPalette(vm: vm, onExport: onExport)
            EditorCanvas(vm: vm, base: base)
            BeautifyPanel(vm: vm)
        }

        let controller = NSHostingController(rootView: root)
        let win = NSWindow(contentViewController: controller)
        win.title = "Annotate"
        win.styleMask = [.titled, .closable, .resizable, .miniaturizable]

        // base.width/height are PIXELS — cap the window to the visible screen so a Retina/large
        // capture doesn't open an oversized, partly off-screen editor. The canvas scales to fit.
        let vf = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let w = min(max(CGFloat(base.width), 480), vf.width * 0.9)
        let h = min(CGFloat(base.height) + 48 + 220, vf.height * 0.9)
        win.setContentSize(CGSize(width: w, height: h))
        win.center()
        win.delegate = self
        win.makeKeyAndOrderFront(nil)
        self.window = win
    }

    private func flattened() -> CGImage {
        let flat = AnnotationRenderer.flatten(base: base, document: vm.document)
        return BeautifyRenderer.render(image: flat, style: vm.beautifyStyle)
    }

    // Auto-copy the annotated result to the clipboard whenever the editor closes — via the
    // close (X) button or Export. (Export already copied; the flag avoids a redundant flatten.)
    func windowWillClose(_ notification: Notification) {
        if !didCopyOnExport {
            sink.copyToClipboard(flattened())
        }
        window = nil
        onClose?()   // let the owner drop its reference (no editor-window leak)
    }
}
