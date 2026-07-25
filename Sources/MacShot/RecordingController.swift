import AppKit
import MacShotCore
@preconcurrency import ScreenCaptureKit

@MainActor final class RecordingController {

    private let overlay: SelectionOverlay
    private let permission: PermissionFlow
    private let notifier: Notifier
    private let prefs: Preferences

    private var state = RecordingState()
    private let recorder = AreaRecorder()
    private let pill = RecordStopPill()
    private var timer: Timer?

    init(overlay: SelectionOverlay, permission: PermissionFlow, notifier: Notifier, prefs: Preferences) {
        self.overlay = overlay
        self.permission = permission
        self.notifier = notifier
        self.prefs = prefs
    }

    var isRecording: Bool { state.isRecording }

    func toggle() {
        if !state.isRecording {
            guard permission.hasScreenAccess() else {
                permission.requestScreenAccess()
                permission.openScreenRecordingSettings()
                return
            }
            overlay.present(mode: .area(nil), windows: [], screenshot: nil, preferences: prefs) { [weak self] result in
                guard let self, case .area(let optRect) = result, let rect = optRect else { return }
                Task { await self.startRecording(area: rect) }
            }
        } else {
            Task { await stopRecording() }
        }
    }

    func stopIfRecording() async {
        guard state.isRecording else { return }
        await stopRecording()
    }

    // MARK: - Private

    private func startRecording(area rect: CGRect) async {
        // Resolve display + scale from SCShareableContent (mirrors SCKScreenCapturer approach)
        let content: SCShareableContent
        do { content = try await SCShareableContent.current }
        catch {
            notifier.notifyError("Couldn't start recording")
            return
        }
        let mainID = CGMainDisplayID()
        let display = content.displays.first(where: { $0.displayID == mainID })
                   ?? content.displays.first
        guard let display else {
            notifier.notifyError("Couldn't start recording")
            return
        }
        // Mirror SCKScreenCapturer.displayScale(_:)
        let scale = NSScreen.screens.first(where: {
            ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) == display.displayID
        })?.backingScaleFactor ?? 2.0

        // Build save URL
        let dirPath = (prefs.saveDirectoryPath as NSString).expandingTildeInPath
        let dir = URL(fileURLWithPath: dirPath, isDirectory: true)
        do { try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true) }
        catch {
            notifier.notifyError("Couldn't start recording")
            return
        }
        let name = FilenameFormatter(format: prefs.filenameFormat)
            .uniqueFilename(for: Date(), mode: "recording", ext: "mp4") {
                FileManager.default.fileExists(atPath: dir.appendingPathComponent($0).path)
            }
        let url = dir.appendingPathComponent(name)

        do {
            try await recorder.start(area: rect, display: display, scale: scale, to: url)
        } catch {
            notifier.notifyError("Couldn't start recording")
            return
        }

        state.start()
        pill.onStop = { [weak self] in self?.toggle() }
        pill.show(near: rect)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.state.tick()
            self.pill.updateLabel("● Stop  " + self.state.label)
        }
    }

    private func stopRecording() async {
        timer?.invalidate()
        timer = nil
        let out = await recorder.stop()
        state.stop()
        pill.hide()
        if let out {
            notifier.notify(title: "Recording saved", body: out.lastPathComponent)
            NSWorkspace.shared.activateFileViewerSelecting([out])
        } else {
            notifier.notifyError("Recording produced no file")
        }
    }
}
