import AppKit
import CoreGraphics
import MacShotCore

@MainActor final class OCRCoordinator {
    private let overlay: SelectionOverlay
    private let capturer: SCKScreenCapturer
    private let ocr: VisionOCRService
    private let notifier: Notifier
    private let permission: PermissionFlow
    private let barcode: BarcodeService

    init(
        overlay: SelectionOverlay,
        capturer: SCKScreenCapturer,
        ocr: VisionOCRService,
        notifier: Notifier,
        permission: PermissionFlow,
        barcode: BarcodeService = VisionBarcodeService()
    ) {
        self.overlay = overlay
        self.capturer = capturer
        self.ocr = ocr
        self.notifier = notifier
        self.permission = permission
        self.barcode = barcode
    }

    // ponytail: barcode errors fall back to [] so OCR-only captures still succeed
    private func detectBarcodesSafely(_ image: CGImage) async -> [BarcodeObservation] {
        (try? await barcode.detect(image)) ?? []
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
            async let ocrObs = ocr.recognize(image)
            async let codes = detectBarcodesSafely(image)
            let text = OCRTextAssembler.assemble(try await ocrObs)
            let payloads = (await codes).map(\.payload)
            let out = BarcodeResult.combinedPayload(text: text, barcodes: payloads)
            guard !out.isEmpty else {
                notifier.notifyError("No text or code recognized")
                return
            }
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(out, forType: .string)
            // ponytail: notification-action Open deferred; URL shown in body, user opens manually
            // upgrade = UNNotificationCategory + UNUserNotificationCenterDelegate in AppDelegate
            var preview = out.count > 80 ? String(out.prefix(80)) + "…" : out
            if payloads.count == 1, BarcodeResult.looksLikeURL(payloads[0]) {
                preview += "\nURL copied — open from clipboard"
            }
            notifier.notify(title: "Text copied", body: preview)
        } catch {
            notifier.notifyError(error.localizedDescription)
        }
    }
}
