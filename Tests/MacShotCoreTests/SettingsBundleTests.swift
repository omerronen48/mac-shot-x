import XCTest
@testable import MacShotCore

final class SettingsBundleTests: XCTestCase {
    func testExportImportRoundtrip() {
        let a = InMemoryKVStore()
        let p = Preferences(store: a)
        p.filenameFormat = "X {date}"; p.captureDelaySeconds = 5; p.copyToClipboard = false
        let data = SettingsBundle.export(from: a)
        let b = InMemoryKVStore()
        SettingsBundle.load(data, into: b)
        let q = Preferences(store: b)
        XCTAssertEqual(q.filenameFormat, "X {date}")
        XCTAssertEqual(q.captureDelaySeconds, 5)
        XCTAssertFalse(q.copyToClipboard)
    }
    func testForeignKeysIgnoredKnownApplied() {
        let store = InMemoryKVStore()
        let json = #"{"totallyUnknownKey":"zzz","filenameFormat":"Y"}"#.data(using: .utf8)!
        SettingsBundle.load(json, into: store)
        XCTAssertEqual(Preferences(store: store).filenameFormat, "Y")
        XCTAssertNil(store.object(forKey: "totallyUnknownKey"))
    }
    func testMissingKeysLeaveDefaults() {
        let store = InMemoryKVStore()
        SettingsBundle.load("{}".data(using: .utf8)!, into: store)
        XCTAssertEqual(Preferences(store: store).filenameFormat, "Screenshot {date} at {time}")
    }
}
