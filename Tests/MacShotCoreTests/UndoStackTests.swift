import XCTest
@testable import MacShotCore

final class UndoStackTests: XCTestCase {
    func ann(_ n: Int) -> [Annotation] {
        [Annotation(kind: .stepNumber(center: .zero, number: n), style: .default)]
    }
    func testUndoRestoresPriorSnapshot() {
        var u = UndoStack(initial: ann(1))
        let s1 = ann(1); let s2 = ann(2)
        u.record(current: s1)                                // record before mutating to s2
        XCTAssertTrue(u.canUndo)
        XCTAssertEqual(u.undo(current: s2), s1)
    }
    func testRedoReapplies() {
        var u = UndoStack(initial: ann(1))
        let s1 = ann(1); let s2 = ann(2)
        u.record(current: s1)
        let undone = u.undo(current: s2)                     // -> s1
        XCTAssertEqual(undone, s1)
        XCTAssertTrue(u.canRedo)
        XCTAssertEqual(u.redo(current: s1), s2)
    }
    func testNewActionClearsRedo() {
        var u = UndoStack(initial: ann(1))
        let s1 = ann(1); let s2 = ann(2)
        u.record(current: s1); _ = u.undo(current: s2)
        XCTAssertTrue(u.canRedo)
        u.record(current: s1)                                // new action clears redo
        XCTAssertFalse(u.canRedo)
    }
}
