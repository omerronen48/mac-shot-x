import XCTest
@testable import MacShotCore

final class PresetStoreTests: XCTestCase {

    func testDefaultPresetsEqualBuiltins() {
        let ps = PresetStore(store: InMemoryKVStore())
        XCTAssertEqual(ps.presets(), BeautifyStyle.builtins)
        XCTAssertEqual(ps.presets().count, 6)
        XCTAssertEqual(ps.presets().first?.name, "None")
    }

    func testSaveNewPresetAppendsAndRoundtrips() {
        let ps = PresetStore(store: InMemoryKVStore())
        let green = BeautifyPreset(name: "MyGreen", style: BeautifyStyle(
            background: .solid(RGBAColor(r: 0, g: 1, b: 0, a: 1)),
            padding: 10, cornerRadius: 5, shadow: nil, scale: 1
        ))
        ps.save(green)
        let all = ps.presets()
        XCTAssertEqual(all.count, 7)
        XCTAssertEqual(all.last, green)
    }

    func testPersistenceAcrossStoreInstances() {
        let store = InMemoryKVStore()
        let green = BeautifyPreset(name: "MyGreen", style: BeautifyStyle(
            background: .solid(RGBAColor(r: 0, g: 1, b: 0, a: 1)),
            padding: 10, cornerRadius: 5, shadow: nil, scale: 1
        ))
        PresetStore(store: store).save(green)
        let all = PresetStore(store: store).presets()
        XCTAssertEqual(all.count, 7)
        XCTAssertTrue(all.contains(green))
    }

    func testDeleteRestoresToBuiltins() {
        let ps = PresetStore(store: InMemoryKVStore())
        let green = BeautifyPreset(name: "MyGreen", style: BeautifyStyle(
            background: .solid(RGBAColor(r: 0, g: 1, b: 0, a: 1)),
            padding: 10, cornerRadius: 5, shadow: nil, scale: 1
        ))
        ps.save(green)
        ps.delete(name: "MyGreen")
        XCTAssertEqual(ps.presets(), BeautifyStyle.builtins)
        XCTAssertEqual(ps.presets().count, 6)
    }

    func testShadowBuiltinAndRestore() {
        let ps = PresetStore(store: InMemoryKVStore())
        let userWhite = BeautifyPreset(name: "White", style: BeautifyStyle(
            background: .solid(RGBAColor(r: 0.9, g: 0.9, b: 0.9, a: 1)),
            padding: 0, cornerRadius: 0, shadow: nil, scale: 1
        ))
        ps.save(userWhite)
        let all = ps.presets()
        XCTAssertEqual(all.count, 6)
        let white = all.first(where: { $0.name == "White" })
        XCTAssertEqual(white, userWhite)

        ps.delete(name: "White")
        let restored = ps.presets()
        XCTAssertEqual(restored.count, 6)
        let builtinWhite = BeautifyStyle.builtins.first(where: { $0.name == "White" })!
        XCTAssertEqual(restored.first(where: { $0.name == "White" }), builtinWhite)
    }
}
