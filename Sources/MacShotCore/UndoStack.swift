/// Snapshot undo/redo over the annotation array. `record` is called *before* a
/// mutation with the state as-is; `undo`/`redo` take the current state to seed
/// the opposite stack.
public struct UndoStack {
    private var past: [[Annotation]] = []
    private var future: [[Annotation]] = []
    public init(initial: [Annotation]) { _ = initial }   // initial kept for symmetry; past starts empty

    public var canUndo: Bool { !past.isEmpty }
    public var canRedo: Bool { !future.isEmpty }

    public mutating func record(current: [Annotation]) {
        past.append(current)
        future.removeAll()          // a new action invalidates the redo branch
    }
    public mutating func undo(current: [Annotation]) -> [Annotation] {
        guard let prev = past.popLast() else { return current }
        future.append(current)
        return prev
    }
    public mutating func redo(current: [Annotation]) -> [Annotation] {
        guard let next = future.popLast() else { return current }
        past.append(current)
        return next
    }
}
