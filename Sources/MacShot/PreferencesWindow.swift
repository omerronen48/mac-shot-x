import SwiftUI
import AppKit
import MacShotCore

// ponytail: minimal ObservableObject; reads/writes Preferences on every set since setters are nonmutating
@MainActor
final class PreferencesModel: ObservableObject {
    let prefs = Preferences(store: UserDefaults.standard)
    var onHotkeysChanged: (() -> Void)?

    @Published var saveDirectoryPath: String
    @Published var filenameFormat: String
    @Published var copyToClipboard: Bool
    @Published var saveToFile: Bool
    @Published var areaHotkey: String
    @Published var windowHotkey: String
    @Published var fullscreenHotkey: String

    init() {
        let p = Preferences(store: UserDefaults.standard)
        saveDirectoryPath = p.saveDirectoryPath
        filenameFormat    = p.filenameFormat
        copyToClipboard   = p.copyToClipboard
        saveToFile        = p.saveToFile
        areaHotkey        = p.areaHotkey
        windowHotkey      = p.windowHotkey
        fullscreenHotkey  = p.fullscreenHotkey
    }

    func commitDirectory(_ path: String) {
        prefs.saveDirectoryPath = path
        saveDirectoryPath = path
    }

    func commitFormat(_ fmt: String) {
        prefs.filenameFormat = fmt
        filenameFormat = fmt
    }

    func commitCopyToClipboard(_ v: Bool) {
        prefs.copyToClipboard = v
    }

    func commitSaveToFile(_ v: Bool) {
        prefs.saveToFile = v
    }

    func commitHotkey(area: String, window: String, fullscreen: String) {
        if (try? HotkeySpec(string: area)) != nil       { prefs.areaHotkey       = area }
        if (try? HotkeySpec(string: window)) != nil     { prefs.windowHotkey     = window }
        if (try? HotkeySpec(string: fullscreen)) != nil { prefs.fullscreenHotkey = fullscreen }
        onHotkeysChanged?()
    }
}

struct PreferencesView: View {
    @ObservedObject var model: PreferencesModel

    // track what's been typed into hotkey fields before commit
    @State private var areaText: String       = ""
    @State private var windowText: String     = ""
    @State private var fullscreenText: String = ""

    private var filenamePreview: String {
        FilenameFormatter(format: model.filenameFormat).filename(for: Date(), mode: "area")
    }

    private var areaError: Bool       { !areaText.isEmpty       && (try? HotkeySpec(string: areaText)) == nil }
    private var windowError: Bool     { !windowText.isEmpty     && (try? HotkeySpec(string: windowText)) == nil }
    private var fullscreenError: Bool { !fullscreenText.isEmpty && (try? HotkeySpec(string: fullscreenText)) == nil }

    var body: some View {
        Form {
            // Save directory
            Section("Save Location") {
                HStack {
                    Text(model.saveDirectoryPath)
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Choose…") { chooseSaveDirectory() }
                }
            }

            // Filename format + live preview
            Section("Filename Format") {
                TextField("Format", text: $model.filenameFormat)
                    .onSubmit { model.commitFormat(model.filenameFormat) }
                Text("Preview: \(filenamePreview)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Toggles
            Section("Behaviour") {
                Toggle("Copy to clipboard", isOn: $model.copyToClipboard)
                    .onChange(of: model.copyToClipboard) { _, v in model.commitCopyToClipboard(v) }
                Toggle("Save to file", isOn: $model.saveToFile)
                    .onChange(of: model.saveToFile) { _, v in model.commitSaveToFile(v) }
            }

            // Hotkey fields
            Section("Hotkeys (e.g. ⌘⇧2)") {
                hotkeyRow(label: "Area capture", text: $areaText, hasError: areaError)
                hotkeyRow(label: "Window capture", text: $windowText, hasError: windowError)
                hotkeyRow(label: "Full-screen capture", text: $fullscreenText, hasError: fullscreenError)
                Button("Apply Hotkeys") {
                    model.commitHotkey(area: areaText, window: windowText, fullscreen: fullscreenText)
                }
                .disabled(areaError || windowError || fullscreenError)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 440, minHeight: 360)
        .padding()
        .onAppear {
            // populate hotkey fields from current prefs
            areaText       = model.areaHotkey
            windowText     = model.windowHotkey
            fullscreenText = model.fullscreenHotkey
        }
    }

    @ViewBuilder
    private func hotkeyRow(label: String, text: Binding<String>, hasError: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label).frame(width: 160, alignment: .leading)
                TextField("", text: text)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
            }
            if hasError {
                Text("Invalid hotkey")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private func chooseSaveDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles       = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        if panel.runModal() == .OK, let url = panel.url {
            model.commitDirectory(url.path)
        }
    }
}

// MARK: - Public entry point

@MainActor
public final class PreferencesWindowController {
    private var window: NSWindow?
    private let model = PreferencesModel()

    /// Callback invoked after any valid hotkey edit and "Apply" press.
    public var onHotkeysChanged: (() -> Void)? {
        get { model.onHotkeysChanged }
        set { model.onHotkeysChanged = newValue }
    }

    public init() {}

    public func show() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view  = PreferencesView(model: model)
        let host  = NSHostingController(rootView: view)
        let win   = NSWindow(contentViewController: host)
        win.title = "MacShot Preferences"
        win.styleMask = [.titled, .closable, .miniaturizable]
        win.center()
        win.isReleasedWhenClosed = false
        self.window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
