import Foundation
import XCTest
import AETHERPhysics

final class WobbleSimulationTests: XCTestCase {
    func testDefaultGridAndExactRest() throws {
        var simulation = try WobbleSimulation(size: SIMD2(640, 480))
        XCTAssertEqual(simulation.columns, 17)
        XCTAssertEqual(simulation.rows, 13)
        XCTAssertEqual(simulation.displacements.count, 221)
        try simulation.impulse(.zero, at: SIMD2(0.5, 0.5))
        for _ in 0..<120 { try simulation.advance(by: 0.1) }
        XCTAssertEqual(simulation.displacements, Array(repeating: .zero, count: 221))
    }

    func testFirstStepMatchesSpringIdentityAndRowMajorSymmetry() throws {
        var simulation = try WobbleSimulation(size: SIMD2(640, 480))
        try simulation.impulse(SIMD2(120, 0), at: SIMD2(0.5, 0.5))
        try simulation.advance(by: 1.0 / 120.0)
        let grid = simulation.displacements
        // Initially every spring displacement is zero. Only damping changes v:
        // x1 = v0 * (1 - 14*dt) * dt at the exact center of this odd grid.
        let expected = 120.0 * (1 - 14.0 / 120.0) / 120.0
        XCTAssertEqual(Double(grid[6 * 17 + 8].x), expected, accuracy: 1e-6)
        XCTAssertEqual(grid[6 * 17 + 8].y, 0)
        XCTAssertGreaterThan(grid[6 * 17 + 8].x, grid[0].x)
        for row in 0..<13 {
            for column in 0..<17 {
                XCTAssertEqual(Double(grid[row * 17 + column].x),
                               Double(grid[(12 - row) * 17 + (16 - column)].x), accuracy: 1e-6)
                XCTAssertEqual(grid[row * 17 + column].y, 0)
            }
        }
        // An off-center impulse resolves to the corresponding row-major node.
        var corner = try WobbleSimulation(size: SIMD2(640, 480), columns: 3, rows: 4)
        try corner.impulse(SIMD2(0, 120), at: SIMD2(0, 1))
        try corner.advance(by: 1.0 / 120.0)
        XCTAssertEqual(corner.displacements.count, 12)
        XCTAssertEqual(Double(corner.displacements[9].y), expected, accuracy: 1e-6)
        XCTAssertGreaterThan(corner.displacements[9].y, corner.displacements[0].y)
    }

    func testSecondStepMatchesCoupledLatticeForceIdentity() throws {
        var simulation = try WobbleSimulation(size: SIMD2(640, 480), columns: 3, rows: 3)
        try simulation.impulse(SIMD2(120, 0), at: SIMD2(0.5, 0.5))
        try simulation.advance(by: 1.0 / 60.0)
        let dt = 1.0 / 120.0
        let centerVelocity = 120 * (1 - 14 * dt)
        let centerPosition = centerVelocity * dt
        let neighborPosition = centerPosition * exp(-0.25 / 0.08)
        let acceleration = -100 * centerPosition + 80 * 4 * (neighborPosition - centerPosition) - 14 * centerVelocity
        let expected = centerPosition + (centerVelocity + acceleration * dt) * dt
        XCTAssertEqual(Double(simulation.displacements[4].x), expected, accuracy: 1e-6)
        XCTAssertEqual(simulation.displacements[4].y, 0)
    }

    func testFixedStepChunkingAndFractionalRemainderAreDeterministic() throws {
        var fine = try WobbleSimulation(size: SIMD2(640, 480))
        try fine.impulse(SIMD2(540, -180), at: SIMD2(0.25, 0.75))
        var coarse = fine
        var fractional = fine
        for _ in 0..<120 { try fine.advance(by: 1.0 / 120.0) }
        for _ in 0..<10 { try coarse.advance(by: 0.1) }
        for _ in 0..<240 { try fractional.advance(by: 1.0 / 240.0) }
        XCTAssertEqual(fine.displacements, coarse.displacements)
        XCTAssertEqual(fine.displacements, fractional.displacements)

        var pending = try WobbleSimulation(size: SIMD2(640, 480))
        try pending.impulse(SIMD2(120, 0), at: SIMD2(0.5, 0.5))
        try pending.advance(by: 1.0 / 240.0)
        XCTAssertTrue(pending.displacements.allSatisfy { $0 == .zero })
        try pending.advance(by: 1.0 / 240.0)
        XCTAssertGreaterThan(pending.displacements[6 * 17 + 8].x, 0)
    }

    func testCatchUpIsClampedAndDoesNotLeaveAWorkBacklog() throws {
        var clamped = try WobbleSimulation(size: SIMD2(640, 480))
        try clamped.impulse(SIMD2(540, 180), at: SIMD2(0.5, 0.5))
        var reference = clamped
        try clamped.advance(by: .greatestFiniteMagnitude)
        try reference.advance(by: 0.1)
        XCTAssertEqual(clamped.displacements, reference.displacements)
        try clamped.advance(by: 0)
        XCTAssertEqual(clamped.displacements, reference.displacements)
        try clamped.advance(by: 1.0 / 120.0)
        try reference.advance(by: 1.0 / 120.0)
        XCTAssertEqual(clamped.displacements, reference.displacements)
    }

    func testRepeatedExtremeImpulsesStayFiniteBoundedAndRecoverExactly() throws {
        var simulation = try WobbleSimulation(size: SIMD2(640, 480))
        for _ in 0..<40 {
            try simulation.impulse(SIMD2(.greatestFiniteMagnitude, -.greatestFiniteMagnitude), at: SIMD2(0, 1))
            try simulation.advance(by: 0.1)
            assertBounded(simulation, maximum: 120)
        }
        XCTAssertTrue(simulation.displacements.contains { $0 != .zero })
        for _ in 0..<120 {
            try simulation.advance(by: 0.1)
            assertBounded(simulation, maximum: 120)
        }
        XCTAssertTrue(simulation.displacements.allSatisfy { $0 == .zero })
        // Rest must be a fixed point, not just a single zero-valued output.
        try simulation.advance(by: 0.1)
        XCTAssertTrue(simulation.displacements.allSatisfy { $0 == .zero })
    }

    func testInvalidInputsThrowWithoutMutatingStateOrFractionalTime() throws {
        let invalidSizes: [SIMD2<Float>] = [SIMD2(0, 480), SIMD2(-1, 480), SIMD2(.nan, 480),
                                             SIMD2(640, .infinity), SIMD2(16_385, 480)]
        for size in invalidSizes {
            XCTAssertThrowsError(try WobbleSimulation(size: size))
        }
        for count in [Int.min, 0, 1, 66, Int.max] {
            XCTAssertThrowsError(try WobbleSimulation(size: SIMD2(640, 480), columns: count))
            XCTAssertThrowsError(try WobbleSimulation(size: SIMD2(640, 480), rows: count))
        }
        var simulation = try WobbleSimulation(size: SIMD2(640, 480))
        try simulation.impulse(SIMD2(120, 0), at: SIMD2(0.5, 0.5))
        try simulation.advance(by: 1.0 / 240.0)
        var reference = simulation
        for duration in [-1.0, Double.nan, .infinity, -.infinity] {
            XCTAssertThrowsError(try simulation.advance(by: duration))
        }
        let invalidVelocities: [SIMD2<Float>] = [SIMD2(.nan, 0), SIMD2(0, .infinity)]
        for velocity in invalidVelocities {
            XCTAssertThrowsError(try simulation.impulse(velocity, at: SIMD2(0.5, 0.5)))
        }
        let invalidAnchors: [SIMD2<Float>] = [SIMD2(-0.1, 0), SIMD2(0, 1.1), SIMD2(.nan, 0), SIMD2(0, .infinity)]
        for anchor in invalidAnchors {
            XCTAssertThrowsError(try simulation.impulse(SIMD2(120, 0), at: anchor))
        }
        try simulation.advance(by: 1.0 / 240.0)
        try reference.advance(by: 1.0 / 240.0)
        XCTAssertEqual(simulation.displacements, reference.displacements)
    }

    private func assertBounded(_ simulation: WobbleSimulation, maximum: Double,
                               file: StaticString = #filePath, line: UInt = #line) {
        for displacement in simulation.displacements {
            XCTAssertTrue(displacement.x.isFinite && displacement.y.isFinite, file: file, line: line)
            XCTAssertLessThanOrEqual(hypot(Double(displacement.x), Double(displacement.y)), maximum + 1e-4,
                                     file: file, line: line)
        }
    }
}