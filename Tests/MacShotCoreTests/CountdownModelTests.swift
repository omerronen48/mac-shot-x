import XCTest
@testable import MacShotCore

final class CountdownModelTests: XCTestCase {
    func testTicksDownToZero() {
        var m = CountdownModel(seconds: 3)
        XCTAssertEqual(m.remaining, 3)
        XCTAssertFalse(m.isDone)
        XCTAssertFalse(m.tick()); XCTAssertEqual(m.remaining, 2)
        XCTAssertFalse(m.tick()); XCTAssertEqual(m.remaining, 1)
        XCTAssertTrue(m.tick());  XCTAssertEqual(m.remaining, 0)
        XCTAssertTrue(m.isDone)
    }
    func testZeroIsImmediatelyDone() {
        let m = CountdownModel(seconds: 0)
        XCTAssertTrue(m.isDone)
    }
    func testNegativeClampsToZero() {
        XCTAssertTrue(CountdownModel(seconds: -5).isDone)
    }
}
