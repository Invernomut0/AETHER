import Foundation
import AETHERShared

public struct SpringSolver: Sendable {
    public init() {}

    public func step(position: Vector2, velocity: Vector2, target: Vector2,
                     stiffness: Double, damping: Double, mass: Double,
                     deltaTime: Double) -> PhysicsBodyState {
        let safeMass = max(mass, 0.0001)
        let dt = min(max(deltaTime, 0), 1.0 / 20.0)
        let displacement = position - target
        let acceleration = displacement * (-stiffness / safeMass) + velocity * (-damping / safeMass)
        let nextVelocity = velocity + acceleration * dt
        let nextPosition = position + nextVelocity * dt
        return PhysicsBodyState(position: nextPosition, velocity: nextVelocity)
    }
}
