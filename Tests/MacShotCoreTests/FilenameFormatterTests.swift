import XCTest
@testable import MacShotCore

final class FilenameFormatterTests: XCTestCase {
    let ts = Date(timeIntervalSince1970: 1_600_000_000) // 2020-09-13 12:26:40 UTC

    func testExpandsDateTimeTokens() {
        let f = FilenameFormatter(format: "Shot {date} at {time}", calendar: .utc)
        XCTAssertEqual(f.filename(for: ts, mode: "area"),
                       "Shot 2020-09-13 at 12-26-40.png")
    }
    func testSanitizesIllegalCharacters() {
        let f = FilenameFormatter(format: "a/b:c{mode}", calendar: .utc)
        let name = f.filename(for: ts, mode: "area")
        XCTAssertFalse(name.contains("/"))
        XCTAssertFalse(name.contains(":"))
    }
    func testDedupesCollisions() {
        let f = FilenameFormatter(format: "x", calendar: .utc)
        let taken: (String) -> Bool = { ["x.png", "x (1).png"].contains($0) }
        XCTAssertEqual(f.uniqueFilename(for: ts, mode: "area", isTaken: taken), "x (2).png")
    }
}

extension Calendar { static var utc: Calendar {
    var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c
} }
