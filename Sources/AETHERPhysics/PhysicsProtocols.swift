import Foundation
import AETHERShared

public protocol PhysicsSimulating: Sendable {
    func addBody(_ body: PhysicsBody) async throws
    func setTarget(_ target: Vector2, for id: UUID) async
    func step(deltaTime: Double) async
    func state(for id: UUID) async -> PhysicsBodyState?
    func removeBody(_ id: UUID) async
}
