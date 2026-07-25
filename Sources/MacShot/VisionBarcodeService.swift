import CoreGraphics
@preconcurrency import Vision
import MacShotCore

struct VisionBarcodeService: BarcodeService {
    func detect(_ image: CGImage) async throws -> [MacShotCore.BarcodeObservation] {
        let w = CGFloat(image.width), h = CGFloat(image.height)
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectBarcodesRequest { req, error in
                if let error { continuation.resume(throwing: error); return }
                let results = (req.results as? [VNBarcodeObservation]) ?? []
                let obs: [MacShotCore.BarcodeObservation] = results.compactMap { r in
                    guard let payload = r.payloadStringValue, !payload.isEmpty else { return nil }
                    let bb = r.boundingBox
                    let rect = CGRect(x: bb.minX * w, y: bb.minY * h,
                                     width: bb.width * w, height: bb.height * h)
                    return MacShotCore.BarcodeObservation(payload: payload,
                                             symbology: r.symbology.rawValue,
                                             boundingBox: rect)
                }
                continuation.resume(returning: obs)
            }
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do { try handler.perform([request]) }
            catch { continuation.resume(throwing: error) }
        }
    }
}
