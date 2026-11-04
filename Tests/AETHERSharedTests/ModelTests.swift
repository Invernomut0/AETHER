import XCTest
@testable import AETHERShared

final class ModelTests: XCTestCase {
    func testWindowIDHashable() {
        XCTAssertEqual(WindowID(rawValue: 42), WindowID(rawValue: 42))
    }

    func testCodableRectRoundTrip() throws {
        let rect = CodableRect(x: 1, y: 2, width: 300, height: 200)
        let data = try JSONEncoder().encode(rect)
        let decoded = try JSONDecoder().decode(CodableRect.self, from: data)
        XCTAssertEqual(decoded, rect)
    }
}
