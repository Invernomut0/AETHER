import Foundation
import AETHERShared

/// Independent displacement lattice, in points, with free edges and a spring to
/// rest at every node. No native windows, clocks or framework objects are owned.
/// All nodes read the previous step, so traversal order cannot bias propagation.
public struct WobbleSimulation: Sendable {
    public let columns: Int
    public let rows: Int
    public var displacements: [SIMD2<Float>] {
        positions.map { SIMD2(Float($0.x), Float($0.y)) }
    }

    private static let timeStep = 1.0 / 120.0
    private let extent: Double
    private let solver = SpringSolver()
    private var positions: [Vector2]
    private var velocities: [Vector2]
    private var nextPositions: [Vector2]
    private var nextVelocities: [Vector2]
    private var accumulatedTime = 0.0

    /// Sizes must be finite, positive and at most 16384 points per edge.
    /// Each grid edge accepts 2...65 nodes (default 17 × 13 = 221).
    public init(size: SIMD2<Float>, columns: Int = 17, rows: Int = 13) throws {
        guard size.x.isFinite, size.y.isFinite, size.x > 0, size.y > 0,
              size.x <= 16_384, size.y <= 16_384,
              (2...65).contains(columns), (2...65).contains(rows) else {
            throw AetherError.invalidState("Invalid wobble size or lattice dimensions")
        }
        self.columns = columns
        self.rows = rows
        extent = Double(min(size.x, size.y))
        positions = Array(repeating: .zero, count: columns * rows)
        velocities = positions
        nextPositions = positions
        nextVelocities = positions
    }

    /// Adds velocity in points/second with a smooth, normalized-space falloff.
    /// The anchor must be in [0, 1]². Finite impulses are saturated to 8 times
    /// the shorter edge per second, including repeated impulses.
    public mutating func impulse(_ velocity: SIMD2<Float>, at normalizedAnchor: SIMD2<Float>) throws {
        guard velocity.x.isFinite, velocity.y.isFinite,
              normalizedAnchor.x.isFinite, normalizedAnchor.y.isFinite,
              (0...1).contains(normalizedAnchor.x), (0...1).contains(normalizedAnchor.y) else {
            throw AetherError.invalidState("Wobble impulse and anchor must be finite; anchor must be normalized")
        }
        let impulse = bounded(Vector2(x: Double(velocity.x), y: Double(velocity.y)), length: extent * 8)
        for row in 0..<rows {
            for column in 0..<columns {
                let dx = Double(column) / Double(columns - 1) - Double(normalizedAnchor.x)
                let dy = Double(row) / Double(rows - 1) - Double(normalizedAnchor.y)
                let weight = exp(-(dx * dx + dy * dy) / 0.08)
                let index = row * columns + column
                velocities[index] = bounded(velocities[index] + impulse * weight, length: extent * 8)
            }
        }
    }

    /// Accumulates fractional steps; integrates at most 0.1 seconds (12 steps)
    /// per call, discarding excess wall time rather than queuing catch-up work.
    /// Negative and nonfinite durations throw without changing the state.
    public mutating func advance(by seconds: Double) throws {
        guard seconds.isFinite, seconds >= 0 else {
            throw AetherError.invalidState("Wobble elapsed time must be finite and nonnegative")
        }
        accumulatedTime += min(seconds, 0.1)
        for _ in 0..<12 {
            // Tolerance only corrects floating-point accumulation at step boundaries.
            guard accumulatedTime + 1e-12 >= Self.timeStep else { break }
            accumulatedTime = max(0, accumulatedTime - Self.timeStep)
            step()
        }
    }

    /// Neighbor forces are k*(neighbor-self); the central spring prevents drift.
    /// Semi-implicit Euler uses unit masses, k=80 per link, k=100 to rest and
    /// damping=14. The maximum stiffness eigenvalue is <=740 at dt=1/120.
    private mutating func step() {
        var maximumPosition = 0.0
        var maximumVelocity = 0.0
        for row in 0..<rows {
            for column in 0..<columns {
                let index = row * columns + column
                var sum = Vector2.zero
                var degree = 0
                if column > 0 { sum = sum + positions[index - 1]; degree += 1 }
                if column + 1 < columns { sum = sum + positions[index + 1]; degree += 1 }
                if row > 0 { sum = sum + positions[index - columns]; degree += 1 }
                if row + 1 < rows { sum = sum + positions[index + columns]; degree += 1 }
                let stiffness = 100 + Double(degree) * 80
                let state = solver.step(position: positions[index], velocity: velocities[index],
                                        target: sum * (80 / stiffness), stiffness: stiffness,
                                        damping: 14, mass: 1, deltaTime: Self.timeStep)
                let position = bounded(state.position, length: extent * 0.25)
                var velocity = bounded(state.velocity, length: extent * 8)
                if position != state.position {
                    // A saturated node cannot keep accelerating through its boundary.
                    let normal = position * (1 / hypot(position.x, position.y))
                    let outwardSpeed = velocity.x * normal.x + velocity.y * normal.y
                    if outwardSpeed > 0 { velocity = velocity - normal * outwardSpeed }
                }
                nextPositions[index] = position
                nextVelocities[index] = velocity
                maximumPosition = max(maximumPosition, hypot(position.x, position.y))
                maximumVelocity = max(maximumVelocity, hypot(velocity.x, velocity.y))
            }
        }
        swap(&positions, &nextPositions)
        swap(&velocities, &nextVelocities)
        if maximumPosition < extent * 1e-6, maximumVelocity < extent * 1e-5 {
            // Snap the entire quiet lattice, never individual propagating nodes.
            for index in positions.indices {
                positions[index] = .zero
                velocities[index] = .zero
            }
        }
    }

    private func bounded(_ value: Vector2, length limit: Double) -> Vector2 {
        let length = hypot(value.x, value.y)
        return length > limit ? value * (limit / length) : value
    }
}