import XCTest
@testable import MacShotCore

final class OverlayStackTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 0)
    func at(_ s: TimeInterval) -> Date { t0.addingTimeInterval(s) }

    func testNewestAtBottomIndexZero() {
        var st = OverlayStack(expiry: 8, visibleCap: 5)
        st.push(id: 1, at: at(0)); st.push(id: 2, at: at(1))
        let v = st.visible(at: at(2))
        XCTAssertEqual(v.map(\.id), [2, 1])          // newest first
        XCTAssertEqual(v.first?.index, 0)             // newest = bottom slot 0
    }
    func testExpiryDropsOldPanels() {
        var st = OverlayStack(expiry: 8, visibleCap: 5)
        st.push(id: 1, at: at(0))
        XCTAssertEqual(st.visible(at: at(7)).map(\.id), [1])
        XCTAssertEqual(st.visible(at: at(8.1)).map(\.id), [])   // past expiry
    }
    func testHoverKeepAlivePausesExpiry() {
        var st = OverlayStack(expiry: 8, visibleCap: 5)
        st.push(id: 1, at: at(0))
        st.keepAlive(id: 1)
        XCTAssertEqual(st.visible(at: at(100)).map(\.id), [1])  // never expires while held
        st.release(id: 1, at: at(100))
        XCTAssertEqual(st.visible(at: at(107)).map(\.id), [1])  // timer restarts from release
        XCTAssertEqual(st.visible(at: at(108.1)).map(\.id), [])
    }
    func testVisibleCapCollapsesOldest() {
        var st = OverlayStack(expiry: 100, visibleCap: 2)
        for i in 1...4 { st.push(id: i, at: at(Double(i))) }
        XCTAssertEqual(st.visible(at: at(5)).map(\.id), [4, 3])  // only newest 2 visible
    }
    func testDismissRemoves() {
        var st = OverlayStack(expiry: 100, visibleCap: 5)
        st.push(id: 1, at: at(0)); st.dismiss(id: 1)
        XCTAssertEqual(st.visible(at: at(1)).map(\.id), [])
    }
}
