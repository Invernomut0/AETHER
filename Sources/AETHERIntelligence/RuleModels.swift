import Foundation
import AETHERShared

public struct AetherRule: Codable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    public var bundleIdentifier: String?
    public var activateLayoutID: UUID?
    public var enabled: Bool
}
