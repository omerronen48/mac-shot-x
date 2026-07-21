import AppKit
import ImageIO
import MacShotCore
import ScreenCaptureKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let prefs = Preferences(store: UserDefaults.standard)
    private let sink = SystemSink()
    private let capturer = SCKScreenCapturer()
    private let notifier = Notifier()
    private let hotkeyManager = HotkeyManager()
    private let permissionFlow = PermissionFlow()
    private let overlay = SelectionOverlay()
    private let prefsWindowController = PreferencesWindowController()
    private var historyWindowController: HistoryWindowController?
    private var overlayController: OverlayController?
    private var ocrCoordinator: OCRCoordinator?
    private var editorWindows: [EditorWindow] = [] // ponytail: retain open editors

    // ponytail: nonisolated(unsafe) lets us call the nonisolated async capture(_:at:) without
    // a Swift-6 "sending across isolation" error — CaptureEngine is not Sendable because
    // Preferences.store is AnyObject (KeyValueStore). AppDelegate owns this exclusively
    // on the main actor, so the unsafety is bounded.
    nonisolated(unsafe) private var engine: CaptureEngine!

    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        engine = CaptureEngine(capturer: capturer, sink: sink, preferences: prefs)

        let saveDir = URL(fileURLWithPath: prefs.saveDirectoryPath, isDirectory: true)
        let pinStore = PinStore(store: UserDefaults.standard)
        let historyStore = HistoryStore(directory: saveDir, pins: pinStore)
        overlayController = OverlayController(historyStore: historyStore)
        historyWindowController = HistoryWindowController(store: historyStore)
        ocrCoordinator = OCRCoordinator(
            overlay: overlay,
            capturer: capturer,
            ocr: VisionOCRService(),
            notifier: notifier,
            permission: permissionFlow
        )

        overlayController?.onEdit = { [weak self] image in self?.openEditor(for: image) }
        overlayController?.onHistory = { [weak self] in self?.openHistory() }
        historyWindowController?.onEdit = { [weak self] entry in
            guard let self, let src = CGImageSourceCreateWithURL(entry.url as CFURL, nil),
                  let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return }
            self.openEditor(for: img)
        }

        NSApp.setActivationPolicy(.accessory)
        buildStatusMenu()

        if !permissionFlow.hasScreenAccess() {
            permissionFlow.requestScreenAccess()
            permissionFlow.openScreenRecordingSettings()
        }

        registerHotkeys()

        prefsWindowController.onHotkeysChanged = { [weak self] in
            self?.hotkeyManager.unregisterAll()
            self?.registerHotkeys()
        }
    }

    // MARK: - Status menu

    private func buildStatusMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "camera.on.rectangle", accessibilityDescription: "MacShot")
        if item.button?.image == nil { item.button?.title = "M" }

        let menu = NSMenu()
        menu.addItem(withTitle: "Capture Area",       action: #selector(captureArea),       keyEquivalent: "")
        menu.addItem(withTitle: "Capture Window",     action: #selector(captureWindow),     keyEquivalent: "")
        menu.addItem(withTitle: "Capture Fullscreen", action: #selector(captureFullscreen), keyEquivalent: "")
        menu.addItem(withTitle: "Capture Text (OCR)", action: #selector(captureText),       keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "History…",     action: #selector(openHistory),     keyEquivalent: "")
        menu.addItem(withTitle: "Preferences…", action: #selector(openPreferences), keyEquivalent: "")
        menu.addItem(withTitle: "Quit",         action: #selector(quitApp),          keyEquivalent: "")
        item.menu = menu
        statusItem = item
    }

    @objc private func captureArea()       { runCapture(mode: .area(nil)) }
    @objc private func captureWindow()     { runCapture(mode: .window(nil)) }
    @objc private func captureFullscreen() { runCapture(mode: .fullscreen(nil)) }
    @objc private func captureText()       { Task { await ocrCoordinator?.run() } }
    @objc private func openHistory()        { historyWindowController?.refresh(); historyWindowController?.show() }
    @objc private func openPreferences()   { prefsWindowController.show() }
    @objc private func quitApp()           { NSApp.terminate(nil) }

    // MARK: - Hotkey registration

    private func registerHotkeys() {
        let specs: [(String, UInt32, CaptureMode)] = [
            (prefs.areaHotkey,       1, .area(nil)),
            (prefs.windowHotkey,     2, .window(nil)),
            (prefs.fullscreenHotkey, 3, .fullscreen(nil)),
        ]
        for (str, id, mode) in specs {
            guard let spec = try? HotkeySpec(string: str) else { continue }
            hotkeyManager.register(spec, id: id) { [weak self] in
                self?.runCapture(mode: mode)
            }
        }
        if let ocrSpec = try? HotkeySpec(string: "⌃⌘⇧O") {
            hotkeyManager.register(ocrSpec, id: 4) { [weak self] in
                Task { await self?.ocrCoordinator?.run() }
            }
        }
    }

    // MARK: - Capture flow

    private func runCapture(mode: CaptureMode) {
        Task { @MainActor in
            let resolvedMode: CaptureMode
            if mode.needsSelectionUI {
                let windowList = (try? await fetchWindowList()) ?? []
                guard let m = await presentOverlay(mode: mode, windows: windowList) else { return }
                resolvedMode = m
            } else {
                resolvedMode = mode
            }

            do {
                let result = try await engine.capture(resolvedMode)
                overlayController?.present(result)
            } catch let err as CaptureError where err == .permissionDenied {
                notifier.notifyError("Screen recording permission denied.")
                permissionFlow.openScreenRecordingSettings()
            } catch {
                notifier.notifyError(error.localizedDescription)
            }
        }
    }

    private func fetchWindowList() async throws -> [(CGWindowID, CGRect)] {
        let content = try await SCShareableContent.current
        // SCWindow.frame is TOP-LEFT-origin global points; the overlay hit-tests in Cocoa
        // bottom-left global points. Flip Y against the primary display's height. Also keep
        // only real, on-screen app windows (layer 0) — excludes desktop/menubar/Dock/tiny —
        // so window picking can't fall through to the full-screen wallpaper. Front-to-back order
        // is preserved so the overlay picks the topmost window under the cursor.
        let primaryHeight = NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height
            ?? NSScreen.main?.frame.height ?? 0
        return content.windows
            .filter { $0.isOnScreen && $0.windowLayer == 0 && $0.frame.width >= 40 && $0.frame.height >= 40 }
            .map { w in
                let f = w.frame
                let cocoa = CGRect(x: f.origin.x, y: primaryHeight - f.origin.y - f.height,
                                   width: f.width, height: f.height)
                return (w.windowID, cocoa)
            }
    }

    // ponytail: bridge completion-handler API to async via continuation
    private func presentOverlay(mode: CaptureMode, windows: [(CGWindowID, CGRect)]) async -> CaptureMode? {
        await withCheckedContinuation { continuation in
            overlay.present(mode: mode, windows: windows) { result in
                continuation.resume(returning: result)
            }
        }
    }

    private func openEditor(for image: CGImage) {
        // ponytail: init shows the window; retain so it isn't released
        editorWindows.append(EditorWindow(base: image, sink: sink, preferences: prefs))
    }
}
