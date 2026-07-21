import Foundation

public struct PanelSlot: Equatable, Sendable {
    public let id: Int
    public let index: Int   // 0 = bottom (newest)
}

/// Pure model of the post-capture panel stack. Injected clock (no wall-clock).
/// A panel expires `expiry` seconds after its `expiresAt` unless kept alive by hover.
public struct OverlayStack: Sendable {
    public var expiry: TimeInterval
    public var visibleCap: Int
    private struct Panel: Sendable { var id: Int; var expiresAt: Date?; var pushedAt: Date }
    private var panels: [Panel] = []

    public init(expiry: TimeInterval = 8, visibleCap: Int = 5) {
        self.expiry = expiry; self.visibleCap = visibleCap
    }

    public mutating func push(id: Int, at now: Date) {
        panels.removeAll { $0.id == id }
        panels.append(Panel(id: id, expiresAt: now.addingTimeInterval(expiry), pushedAt: now))
    }
    public mutating func keepAlive(id: Int) {
        if let i = panels.firstIndex(where: { $0.id == id }) { panels[i].expiresAt = nil }
    }
    public mutating func release(id: Int, at now: Date) {
        if let i = panels.firstIndex(where: { $0.id == id }) {
            panels[i].expiresAt = now.addingTimeInterval(expiry)
        }
    }
    public mutating func dismiss(id: Int) { panels.removeAll { $0.id == id } }

    /// Non-expired panels, newest-first, capped to `visibleCap`.
    public func visible(at now: Date) -> [PanelSlot] {
        let alive = panels.filter { $0.expiresAt == nil || $0.expiresAt! > now }
            .sorted { $0.pushedAt > $1.pushedAt }        // newest first
            .prefix(visibleCap)
        return alive.enumerated().map { PanelSlot(id: $0.element.id, index: $0.offset) }
    }
}
