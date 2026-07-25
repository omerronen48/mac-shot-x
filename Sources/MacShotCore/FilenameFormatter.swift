import Foundation

/// Expands a user format string + timestamp into a safe PNG filename.
/// Tokens: {date}=yyyy-MM-dd, {time}=HH-mm-ss, {mode}=capture slug.
public struct FilenameFormatter {
    public let format: String
    public var calendar: Calendar
    public init(format: String, calendar: Calendar = .current) {
        self.format = format; self.calendar = calendar
    }

    private static let illegal = CharacterSet(charactersIn: "/\\:*?\"<>|")

    public func filename(for date: Date, mode: String, ext: String = "png") -> String {
        let df = DateFormatter(); df.calendar = calendar; df.timeZone = calendar.timeZone; df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"; let d = df.string(from: date)
        df.dateFormat = "HH-mm-ss";   let t = df.string(from: date)
        var s = format
            .replacingOccurrences(of: "{date}", with: d)
            .replacingOccurrences(of: "{time}", with: t)
            .replacingOccurrences(of: "{mode}", with: mode)
        s = String(s.unicodeScalars.map { Self.illegal.contains($0) ? Character("-") : Character($0) })
        return s.isEmpty ? "Screenshot.\(ext)" : s + ".\(ext)"
    }

    /// Appends " (n)" until `isTaken` returns false.
    public func uniqueFilename(for date: Date, mode: String, ext: String = "png", isTaken: (String) -> Bool) -> String {
        let base = filename(for: date, mode: mode, ext: ext)
        if !isTaken(base) { return base }
        let stem = String(base.dropLast(ext.count + 1)) // strip .<ext>
        var n = 1
        while isTaken("\(stem) (\(n)).\(ext)") { n += 1 }
        return "\(stem) (\(n)).\(ext)"
    }
}
