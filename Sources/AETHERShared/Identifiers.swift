import Foundation
import CoreGraphics

public struct WindowID: Hashable, Codable, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
}

public struct RuntimeWindowHandle: Hashable, Codable, Sendable {
    public let windowID: WindowID
    public let processID: Int32
    public let generation: UUID
    public init(windowID: WindowID, processID: Int32, generation: UUID = UUID()) {
        self.windowID = windowID
        self.processID = processID
        self.generation = generation
    }
}

public struct EffectID: Hashable, Codable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }
}

public struct WorkspaceID: Hashable, Codable, Sendable {
    public let rawValue: UUID
    public init(rawValue: UUID = UUID()) { self.rawValue = rawValue }
}

public struct AnimationID: Hashable, Codable, Sendable {
    public let rawValue: UUID
    public init(rawValue: UUID = UUID()) { self.rawValue = rawValue }
}

public struct DisplayID: Hashable, Codable, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
}

public struct PresetID: Hashable, Codable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}
