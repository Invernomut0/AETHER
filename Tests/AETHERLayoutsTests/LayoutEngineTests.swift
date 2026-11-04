import XCTest
@testable import AETHERLayouts
import AETHERShared

final class LayoutEngineTests: XCTestCase {
    func testLeafLayoutProducesFrame() throws {
        let id = WindowID(rawValue: 7)
        let node = LayoutNode(id: UUID(), kind: .leaf, children: [], windowID: id, ratio: nil)
        let engine = LayoutEngine()
        let frames = try engine.frames(for: node, in: CodableRect(x: 0, y: 0, width: 800, height: 600), spacing: 0)
        XCTAssertEqual(frames[id]?.size.width, 800)
    }

    func testDuplicateWindowIsRejected() {
        let id = WindowID(rawValue: 7)
        let a = LayoutNode(id: UUID(), kind: .leaf, children: [], windowID: id, ratio: nil)
        let b = LayoutNode(id: UUID(), kind: .leaf, children: [], windowID: id, ratio: nil)
        let root = LayoutNode(id: UUID(), kind: .stack, children: [a, b], windowID: nil, ratio: nil)
        XCTAssertThrowsError(try LayoutEngine().validate(root))
    }
}
