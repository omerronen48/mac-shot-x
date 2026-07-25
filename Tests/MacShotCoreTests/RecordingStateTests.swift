import XCTest
@testable import MacShotCore

final class RecordingStateTests: XCTestCase {
    func testStartTickStop() {
        var s = RecordingState()
        XCTAssertFalse(s.isRecording); XCTAssertEqual(s.elapsedSeconds, 0)
        s.start(); XCTAssertTrue(s.isRecording)
        s.tick(); s.tick(); s.tick(); XCTAssertEqual(s.elapsedSeconds, 3)
        s.stop(); XCTAssertFalse(s.isRecording)
    }
    func testNoTickWhenIdle() {
        var s = RecordingState(); s.tick(); XCTAssertEqual(s.elapsedSeconds, 0)
    }
    func testStartResetsElapsed() {
        var s = RecordingState(); s.start(); s.tick(); s.stop(); s.start()
        XCTAssertEqual(s.elapsedSeconds, 0)
    }
    func testLabelMMSS() {
        var s = RecordingState(); s.start(); for _ in 0..<75 { s.tick() }
        XCTAssertEqual(s.label, "1:15")
    }
}
