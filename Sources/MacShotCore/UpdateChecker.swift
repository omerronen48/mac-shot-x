import Foundation

/// Pure version-comparison logic for the "Check for Updates" feature. The network fetch of
/// the latest GitHub release lives in the app shell; this decides whether a tag is newer.
public enum UpdateChecker {
    /// True iff `latest` is a strictly higher version than `current`. Accepts a leading "v"
    /// and dotted numeric components ("v0.2.0" > "0.1.9"); missing components count as 0.
    public static func isNewer(_ latest: String, than current: String) -> Bool {
        let a = components(latest), b = components(current)
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    static func components(_ s: String) -> [Int] {
        s.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
            .split(separator: ".")
            .map { Int(String($0).prefix(while: \.isNumber)) ?? 0 }
    }
}
