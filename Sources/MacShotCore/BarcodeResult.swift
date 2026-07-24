import Foundation

public enum BarcodeResult {
    public static func combinedPayload(text: String, barcodes: [String]) -> String {
        barcodes.isEmpty ? text : barcodes.joined(separator: "\n")
    }

    public static func looksLikeURL(_ string: String) -> Bool {
        let s = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return s.hasPrefix("http://") || s.hasPrefix("https://")
    }
}
