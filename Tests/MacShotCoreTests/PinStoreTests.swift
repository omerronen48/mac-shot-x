import XCTest
@testable import MacShotCore

final class PinStoreTests: XCTestCase {
    func testAddRemoveRoundtrip() {
        let store = InMemoryKVStore()
        let pins = PinStore(store: store)
        XCTAssertTrue(pins.pins().isEmpty)
        pins.add("/a/x.png"); pins.add("/a/y.png")
        XCTAssertEqual(pins.pins(), ["/a/x.png", "/a/y.png"])
        pins.remove("/a/x.png")
        XCTAssertEqual(pins.pins(), ["/a/y.png"])
        // survives a fresh instance over the same store
        XCTAssertEqual(PinStore(store: store).pins(), ["/a/y.png"])
    }
    func testAddIsIdempotent() {
        let pins = PinStore(store: InMemoryKVStore())
        pins.add("/a/x.png"); pins.add("/a/x.png")
        XCTAssertEqual(pins.pins().count, 1)
    }
}
