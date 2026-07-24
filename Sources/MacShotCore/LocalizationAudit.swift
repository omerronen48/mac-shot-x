import Foundation

/// Checks a `.xcstrings` catalog for required keys that lack a base entry or any requested
/// language's non-empty value. Returns the missing keys ([] = complete). CI-guard.
public enum LocalizationAudit {
    public static func missingKeys(catalogJSON: Data, required: [String], languages: [String]) -> [String] {
        let root = (try? JSONSerialization.jsonObject(with: catalogJSON)) as? [String: Any]
        let strings = (root?["strings"] as? [String: Any]) ?? [:]
        var missing: [String] = []
        for key in required {
            guard let entry = strings[key] as? [String: Any] else { missing.append(key); continue }
            let locs = (entry["localizations"] as? [String: Any]) ?? [:]
            let complete = languages.allSatisfy { lang in
                guard let l = locs[lang] as? [String: Any],
                      let unit = l["stringUnit"] as? [String: Any],
                      let v = unit["value"] as? String, !v.isEmpty else { return false }
                return true
            }
            if !complete { missing.append(key) }
        }
        return missing
    }
}
