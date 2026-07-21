import AppKit
import CoreGraphics
import MacShotCore

@MainActor final class OCRCoordinator {
    private let overlay: SelectionOverlay
    private let capturer: SCKScreenCapturer
    private let ocr: VisionOCRService
    private let notifier: Notifier
    private let permission: PermissionFlow

    init(
        overlay: SelectionOverlay,
        capturer: SCKScreenCapturer,
        ocr: VisionOCRService,
        notifier: Notifier,
        permission: PermissionFlow
    ) {
        self.overlay = overlay
        self.capturer = capturer
        self.ocr = ocr
        self.notifier = notifier
        self.permission = permission
    }

    func run() async {
        guard permission.hasScreenAccess() else {
            permission.requestScreenAccess()
            permission.openScreenRecordingSettings()
            return
        }

        let selected: CaptureMode? = await withCheckedContinuation { cont in
            overlay.present(mode: .area(nil), windows: []) { cont.resume(returning: $0) }
        }
        guard case let .area(rect?) = selected else { return }

        do {
            let image = try await capturer.capture(.area(rect))
            let obs = try await ocr.recognize(image)
            let text = OCRTextAssembler.assemble(obs)
            guard !text.isEmpty else {
                notifier.notifyError("No text recognized")
                return
            }
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(text, forType: .string)
            let preview = text.count > 80 ? String(text.prefix(80)) + "…" : text
            notifier.notify(title: "Text copied", body: preview)
        } catch {
            notifier.notifyError(error.localizedDescription)
        }
    }
}
