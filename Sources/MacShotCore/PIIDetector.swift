import CoreGraphics
import Foundation

public enum PIIDetector {

    // ponytail: compile once at load time; five patterns cover all PII classes in spec
    private static let patterns: [NSRegularExpression] = {
        let raw = [
            // email
            #"[\w.%+\-]+@[\w.\-]+\.[A-Za-z]{2,}"#,
            // phone: 8+ digits with optional spaces/parens/dashes/plus
            #"[\+\(]?[\d][\d\s\-\(\)]{6,}[\d]"#,
            // credit card: 13-19 digits with optional single space/dash separators
            #"\b\d{4}[\s\-]\d{4}[\s\-]\d{4}(?:[\s\-]\d{1,7})?\b|\b\d{13,19}\b"#,
            // long digits: 9+ digit run
            #"\b\d{9,}\b"#,
            // API-key-like: 20+ word chars containing at least one letter AND one digit
            #"\b[A-Za-z0-9_\-]{20,}\b"#,
        ]
        return raw.map { try! NSRegularExpression(pattern: $0) }
    }()

    // Extra guard for API key: must have ≥1 letter and ≥1 digit
    private static let hasLetter = try! NSRegularExpression(pattern: "[A-Za-z]")
    private static let hasDigit  = try! NSRegularExpression(pattern: "[0-9]")

    public static func matches(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..., in: text)
        for (i, re) in patterns.enumerated() {
            guard let m = re.firstMatch(in: text, range: range) else { continue }
            if i == 4 {
                // API-key pattern: enforce mixed letter+digit
                guard let swiftRange = Range(m.range, in: text) else { continue }
                let candidate = String(text[swiftRange])
                let cr = NSRange(candidate.startIndex..., in: candidate)
                guard hasLetter.firstMatch(in: candidate, range: cr) != nil,
                      hasDigit.firstMatch(in: candidate, range: cr) != nil else { continue }
            }
            return true
        }
        return false
    }

    public static func detect(_ observations: [OCRObservation]) -> [CGRect] {
        var seen = Set<String>()
        var out  = [CGRect]()
        for o in observations where matches(o.text) {
            let key = "\(o.boundingBox)"
            if seen.insert(key).inserted { out.append(o.boundingBox) }
        }
        return out
    }
}
