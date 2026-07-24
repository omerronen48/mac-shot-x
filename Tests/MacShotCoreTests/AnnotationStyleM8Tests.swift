import XCTest
@testable import MacShotCore

final class AnnotationStyleM8Tests: XCTestCase {
    func testNewFieldDefaults() {
        let s = AnnotationStyle.default
        XCTAssertFalse(s.textOutline)
        XCTAssertNil(s.textBackgroundColor)
        XCTAssertEqual(s.textAlignment, .left)
    }
    func testM3EraJSONDecodesWithDefaults() throws {
        let json = #"{"strokeColor":{"r":1,"g":0,"b":0,"a":1},"fillColor":null,"lineWidth":3,"fontSize":17}"#
            .data(using: .utf8)!
        let s = try JSONDecoder().decode(AnnotationStyle.self, from: json)
        XCTAssertFalse(s.textOutline)
        XCTAssertNil(s.textBackgroundColor)
        XCTAssertEqual(s.textAlignment, .left)
        XCTAssertEqual(s.lineWidth, 3)
    }
    func testNewFieldsRoundtrip() throws {
        var s = AnnotationStyle.default
        s.textOutline = true; s.textBackgroundColor = .yellow40; s.textAlignment = .center
        XCTAssertEqual(try JSONDecoder().decode(AnnotationStyle.self, from: JSONEncoder().encode(s)), s)
    }
}
