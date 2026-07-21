import XCTest
@testable import MacShotCore

final class BeautifyStyleTests: XCTestCase {

    // MARK: – BeautifyStyle.none

    func testNoneDefaults() {
        let s = BeautifyStyle.none
        XCTAssertEqual(s.padding, 0)
        XCTAssertEqual(s.cornerRadius, 0)
        XCTAssertNil(s.shadow)
        XCTAssertEqual(s.scale, 1)
    }

    // MARK: – builtins

    func testBuiltinsCount() {
        XCTAssertEqual(BeautifyStyle.builtins.count, 6)
    }

    func testBuiltinsFirstIsNone() {
        XCTAssertEqual(BeautifyStyle.builtins.first?.name, "None")
    }

    // MARK: – Codable round-trips

    func testGradientStyleCodableRoundTrip() throws {
        let shadow = BeautifyShadow(
            color: RGBAColor(r: 0, g: 0, b: 0, a: 1),
            radius: 24,
            opacity: 0.35,
            offset: CGSize(width: 0, height: 10)
        )
        let style = BeautifyStyle(
            background: .linearGradient(
                colors: [RGBAColor(r: 0.2, g: 0.5, b: 1, a: 1),
                         RGBAColor(r: 0.1, g: 0.2, b: 0.6, a: 1)],
                angle: 135
            ),
            padding: 48,
            cornerRadius: 14,
            shadow: shadow,
            scale: 2
        )
        let data = try JSONEncoder().encode(style)
        let decoded = try JSONDecoder().decode(BeautifyStyle.self, from: data)
        XCTAssertEqual(decoded, style)
    }

    func testImageBackgroundCodableRoundTrip() throws {
        let style = BeautifyStyle(
            background: .image(path: "/tmp/bg.png"),
            padding: 20,
            cornerRadius: 8,
            shadow: nil,
            scale: 1
        )
        let data = try JSONEncoder().encode(style)
        let decoded = try JSONDecoder().decode(BeautifyStyle.self, from: data)
        XCTAssertEqual(decoded, style)
    }

    func testPresetCodableRoundTrip() throws {
        let preset = BeautifyPreset(
            name: "Test",
            style: BeautifyStyle(
                background: .solid(RGBAColor(r: 1, g: 0, b: 0, a: 1)),
                padding: 10,
                cornerRadius: 5,
                shadow: nil,
                scale: 1.5
            )
        )
        let data = try JSONEncoder().encode(preset)
        let decoded = try JSONDecoder().decode(BeautifyPreset.self, from: data)
        XCTAssertEqual(decoded, preset)
    }
}
