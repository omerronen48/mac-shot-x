import CoreGraphics
import Vision
import MacShotCore

struct VisionOCRService: OCRService {
    func recognize(_ image: CGImage) async throws -> [OCRObservation] {
        let w = CGFloat(image.width), h = CGFloat(image.height)
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { req, error in
                if let error { continuation.resume(throwing: error); return }
                let results = (req.results as? [VNRecognizedTextObservation]) ?? []
                let obs: [OCRObservation] = results.compactMap { r in
                    guard let cand = r.topCandidates(1).first else { return nil }
                    let bb = r.boundingBox
                    let rect = CGRect(x: bb.minX * w, y: bb.minY * h,
                                     width: bb.width * w, height: bb.height * h)
                    if rect.width == 0 || rect.height == 0 { return nil }
                    return OCRObservation(text: cand.string, boundingBox: rect,
                                         confidence: Double(cand.confidence))
                }
                continuation.resume(returning: obs)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.automaticallyDetectsLanguage = true
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do { try handler.perform([request]) }
            catch { continuation.resume(throwing: error) }
        }
    }
}
