import AppKit
import SwiftUI
import MacShotCore

/// Hosts the annotation editor in an NSWindow; exports a flattened PNG + copies to clipboard.
@MainActor
final class EditorWindow: NSObject {
    private var window: NSWindow?
    private let sink: SystemSink
    private let preferences: Preferences

    init(base: CGImage, sink: SystemSink, preferences: Preferences) {
        self.sink = sink
        self.preferences = preferences
        super.init()

        let doc = AnnotationDocument(baseSize: CGSize(width: base.width, height: base.height))
        let vm = EditorViewModel(document: doc)

        // ponytail: capture [base, vm] by value/reference — base is a CGImage (class), vm is a class
        let onExport: () -> Void = { [weak self] in
            guard let self else { return }
            let flat = AnnotationRenderer.flatten(base: base, document: vm.document)
            sink.copyToClipboard(flat)
            let dir = URL(fileURLWithPath: preferences.saveDirectoryPath, isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let formatter = FilenameFormatter(format: preferences.filenameFormat)
            let name = formatter.uniqueFilename(for: Date(), mode: "annotated") {
                FileManager.default.fileExists(atPath: dir.appendingPathComponent($0).path)
            }
            _ = try? sink.writePNG(flat, suggestedName: name, inDirectory: dir)
            self.window?.close()
            self.window = nil
        }

        let root = VStack(spacing: 0) {
            ToolPalette(vm: vm, onExport: onExport)
            EditorCanvas(vm: vm, base: base)
        }

        let controller = NSHostingController(rootView: root)
        let win = NSWindow(contentViewController: controller)
        win.title = "Annotate"
        win.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        win.setContentSize(CGSize(width: CGFloat(base.width), height: CGFloat(base.height) + 48))
        win.center()
        win.makeKeyAndOrderFront(nil)
        self.window = win
    }
}
