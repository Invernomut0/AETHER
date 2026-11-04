import XCTest
@testable import AETHERAnimation

final class EasingTests: XCTestCase {
    func testEasingEndpoints() {
        XCTAssertEqual(Easing.linear(0), 0)
        XCTAssertEqual(Easing.linear(1), 1)
        XCTAssertEqual(Easing.easeInOut(0), 0)
        XCTAssertEqual(Easing.easeInOut(1), 1)
    }
}
