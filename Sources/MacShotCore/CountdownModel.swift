/// Self-timer tick model: counts whole seconds down to zero.
public struct CountdownModel {
    public private(set) var remaining: Int
    public init(seconds: Int) { remaining = max(0, seconds) }
    public var isDone: Bool { remaining <= 0 }
    /// Decrement one second; returns true when it hits 0.
    @discardableResult
    public mutating func tick() -> Bool {
        if remaining > 0 { remaining -= 1 }
        return remaining == 0
    }
}
