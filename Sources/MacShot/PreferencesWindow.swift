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
    @Published var ocrHotkey: String
    @Published var launchAtLogin: Bool

    init() {
        let p = Preferences(store: UserDefaults.standard)
        saveDirectoryPath = p.saveDirectoryPath
        filenameFormat    = p.filenameFormat
        copyToClipboard   = p.copyToClipboard
        saveToFile        = p.saveToFile
        areaHotkey        = p.areaHotkey
        windowHotkey      = p.windowHotkey
        fullscreenHotkey  = p.fullscreenHotkey
        ocrHotkey         = p.ocrHotkey
        launchAtLogin     = LoginItem.isEnabled   // system status is the source of truth
    }

    func setLaunchAtLogin(_ on: Bool) {
        LoginItem.setEnabled(on)
        launchAtLogin = LoginItem.isEnabled       // reflect real status (register can fail)
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

    func recordArea(_ spec: HotkeySpec) {
        prefs.areaHotkey = spec.description
        areaHotkey = spec.description
        onHotkeysChanged?()
    }

    func recordWindow(_ spec: HotkeySpec) {
        prefs.windowHotkey = spec.description
        windowHotkey = spec.description
        onHotkeysChanged?()
    }

    func recordFullscreen(_ spec: HotkeySpec) {
        prefs.fullscreenHotkey = spec.description
        fullscreenHotkey = spec.description
        onHotkeysChanged?()
    }

    func recordOCR(_ spec: HotkeySpec) {
        prefs.ocrHotkey = spec.description   // persist so registerHotkeys() picks it up
        ocrHotkey = spec.description
        onHotkeysChanged?()
    }
}

struct PreferencesView: View {
    @ObservedObject var model: PreferencesModel

    private var filenamePreview: String {
        FilenameFormatter(format: model.filenameFormat).filename(for: Date(), mode: "area")
    }

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
                Toggle("Launch at login", isOn: $model.launchAtLogin)
                    .onChange(of: model.launchAtLogin) { _, v in model.setLaunchAtLogin(v) }
            }

            Section("Updates") {
                HStack {
                    Text("MacShot \(UpdateService.currentVersion)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Check for Updates…") { UpdateService.checkForUpdates() }
                }
            }

            // Hotkey recorder fields — click to record, Esc to cancel
            Section("Hotkeys") {
                hotkeyRow(label: "Area capture") {
                    HotkeyRecorderField(current: model.areaHotkey) { model.recordArea($0) }
                }
                hotkeyRow(label: "Window capture") {
                    HotkeyRecorderField(current: model.windowHotkey) { model.recordWindow($0) }
                }
                hotkeyRow(label: "Full-screen capture") {
                    HotkeyRecorderField(current: model.fullscreenHotkey) { model.recordFullscreen($0) }
                }
                hotkeyRow(label: "OCR capture") {
                    HotkeyRecorderField(current: model.ocrHotkey) { model.recordOCR($0) }
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 440, minHeight: 360)
        .padding()
    }

    @ViewBuilder
    private func hotkeyRow<F: View>(label: String, @ViewBuilder field: () -> F) -> some View {
        HStack {
            Text(label).frame(width: 160, alignment: .leading)
            field().frame(width: 140, height: 22)
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

    /// Callback invoked after any valid hotkey recording.
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
