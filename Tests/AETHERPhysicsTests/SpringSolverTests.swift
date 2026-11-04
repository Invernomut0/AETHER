import XCTest
@testable import AETHERPhysics
import AETHERShared

final class SpringSolverTests: XCTestCase {
    func testSpringMovesTowardTarget() {
        let solver = SpringSolver()
        let result = solver.step(
            position: Vector2(x: 0, y: 0),
            velocity: .zero,
            target: Vector2(x: 100, y: 0),
            stiffness: 100,
            damping: 10,
            mass: 1,
            deltaTime: 1.0 / 60.0
        )
        XCTAssertGreaterThan(result.position.x, 0)
    }
}
