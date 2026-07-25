import XCTest
@testable import MacShotCore

final class FilenameFormatterExtTests: XCTestCase {
    let ts = Date(timeIntervalSince1970: 1_600_000_000)

    func testExtMp4() {
        let f = FilenameFormatter(format: "Shot {date}", calendar: .utc)
        XCTAssertTrue(f.filename(for: ts, mode: "recording", ext: "mp4").hasSuffix(".mp4"))
    }

    func testDefaultExtStillPng() {
        let f = FilenameFormatter(format: "Shot {date}", calendar: .utc)
        XCTAssertTrue(f.filename(for: ts, mode: "area").hasSuffix(".png"))
    }

    func testUniqueFilenameExtCollision() {
        let f = FilenameFormatter(format: "x", calendar: .utc)
        let taken: (String) -> Bool = { $0 == "x.mp4" }
        XCTAssertEqual(f.uniqueFilename(for: ts, mode: "recording", ext: "mp4", isTaken: taken), "x (1).mp4")
    }
}
