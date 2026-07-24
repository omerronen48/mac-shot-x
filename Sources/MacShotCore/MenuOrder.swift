public enum CaptureAction: String, Codable, CaseIterable, Sendable {
    case area, window, fullscreen, ocr, lastArea
}

public struct MenuOrder: Equatable, Codable, Sendable {
    public var items: [CaptureAction]
    public init(items: [CaptureAction]) { self.items = items }
    public static let `default` = MenuOrder(items: CaptureAction.allCases)

    public mutating func move(from: Int, to: Int) {
        guard items.indices.contains(from) else { return }
        let x = items.remove(at: from)
        items.insert(x, at: min(max(0, to), items.count))
    }
    /// Every action once, dedup preserving first occurrence, missing appended in canonical order.
    public func normalized() -> MenuOrder {
        var seen = Set<CaptureAction>(); var out: [CaptureAction] = []
        for a in items where !seen.contains(a) { seen.insert(a); out.append(a) }
        for a in CaptureAction.allCases where !seen.contains(a) { out.append(a) }
        return MenuOrder(items: out)
    }
}
