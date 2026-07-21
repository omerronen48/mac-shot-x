import XCTest
@testable import MacShotCore

final class UpdateCheckerTests: XCTestCase {
    func testNewerPatchAndMinorAndMajor() {
        XCTAssertTrue(UpdateChecker.isNewer("0.1.1", than: "0.1.0"))
        XCTAssertTrue(UpdateChecker.isNewer("0.2.0", than: "0.1.9"))
        XCTAssertTrue(UpdateChecker.isNewer("1.0.0", than: "0.9.9"))
    }
    func testLeadingVIgnored() {
        XCTAssertTrue(UpdateChecker.isNewer("v0.2.0", than: "0.1.0"))
        XCTAssertFalse(UpdateChecker.isNewer("v0.1.0", than: "0.1.0"))
    }
    func testEqualAndOlderAreNotNewer() {
        XCTAssertFalse(UpdateChecker.isNewer("0.1.0", than: "0.1.0"))
        XCTAssertFalse(UpdateChecker.isNewer("0.1.0", than: "0.2.0"))
    }
    func testMissingComponentsCountAsZero() {
        XCTAssertTrue(UpdateChecker.isNewer("1.0", than: "0.9.9"))
        XCTAssertFalse(UpdateChecker.isNewer("1.0", than: "1.0.0"))
    }
}
