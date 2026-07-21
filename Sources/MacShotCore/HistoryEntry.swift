import Foundation

public struct HistoryEntry: Equatable, Sendable {
    public let url: URL
    public let filename: String
    public let captureDate: Date
    public let isPinned: Bool
    public init(url: URL, filename: String, captureDate: Date, isPinned: Bool) {
        self.url = url; self.filename = filename; self.captureDate = captureDate; self.isPinned = isPinned
    }
}
