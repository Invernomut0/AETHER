import Foundation
import AETHERShared

public actor PhysicsWorld: PhysicsSimulating {
    private struct BodyRecord {
        var body: PhysicsBody
        var target: Vector2
    }
    private var bodies: [UUID: BodyRecord] = [:]
    private let solver = SpringSolver()

    public init() {}

    public func addBody(_ body: PhysicsBody) async throws {
        guard body.mass > 0, body.stiffness >= 0, body.damping >= 0 else {
            throw AetherError.invalidState("Physics body parameters are invalid")
        }
        bodies[body.id] = BodyRecord(body: body, target: body.position)
    }

    public func setTarget(_ target: Vector2, for id: UUID) async {
        bodies[id]?.target = target
    }

    public func step(deltaTime: Double) async {
        for (id, record) in bodies {
            let state = solver.step(
                position: record.body.position,
                velocity: record.body.velocity,
                target: record.target,
                stiffness: record.body.stiffness,
                damping: record.body.damping,
                mass: record.body.mass,
                deltaTime: deltaTime
            )
            bodies[id]?.body.position = state.position
            bodies[id]?.body.velocity = state.velocity
        }
    }

    public func state(for id: UUID) async -> PhysicsBodyState? {
        guard let body = bodies[id]?.body else { return nil }
        return PhysicsBodyState(position: body.position, velocity: body.velocity)
    }

    public func removeBody(_ id: UUID) async { bodies.removeValue(forKey: id) }
}
