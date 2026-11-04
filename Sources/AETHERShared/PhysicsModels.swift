import Foundation

public struct Vector2: Codable, Sendable, Equatable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
    public static let zero = Vector2(x: 0, y: 0)
    public static func + (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    public static func - (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    public static func * (lhs: Vector2, rhs: Double) -> Vector2 {
        Vector2(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}

public struct PhysicsBody: Codable, Sendable {
    public var id: UUID
    public var position: Vector2
    public var velocity: Vector2
    public var mass: Double
    public var damping: Double
    public var stiffness: Double
    public var elasticity: Double
    public var gravityScale: Double
}

public struct PhysicsBodyState: Codable, Sendable {
    public var position: Vector2
    public var velocity: Vector2

    public init(position: Vector2, velocity: Vector2) {
        self.position = position
        self.velocity = velocity
    }
}
