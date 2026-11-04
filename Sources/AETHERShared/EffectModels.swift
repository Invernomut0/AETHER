import Foundation

public enum EffectCategory: String, Codable, Sendable, CaseIterable {
    case window, transition, destruction, spatial, environment
}

public enum EffectTrigger: String, Codable, Sendable, CaseIterable {
    case move, resize, focus, minimize, restore, close, workspaceSwitch, manual
}

public enum PerformanceClass: String, Codable, Sendable {
    case low, medium, high, experimental
}

public enum EffectValue: Codable, Sendable, Equatable {
    case number(Double)
    case bool(Bool)
    case string(String)
    case vector2(Double, Double)
    case color(Double, Double, Double, Double)
}

public struct EffectParameter: Codable, Sendable, Identifiable {
    public var id: String
    public var displayName: String
    public var defaultValue: EffectValue
    public var minimum: Double?
    public var maximum: Double?
}

public struct EffectDescriptor: Codable, Sendable, Identifiable {
    public var id: EffectID
    public var name: String
    public var category: EffectCategory
    public var version: Int
    public var supportedTriggers: [EffectTrigger]
    public var parameters: [EffectParameter]
    public var performanceClass: PerformanceClass
    public var requiresCapture: Bool
    public var requires3D: Bool

    public init(id: EffectID, name: String, category: EffectCategory, version: Int,
                supportedTriggers: [EffectTrigger], parameters: [EffectParameter],
                performanceClass: PerformanceClass, requiresCapture: Bool, requires3D: Bool) {
        self.id = id
        self.name = name
        self.category = category
        self.version = version
        self.supportedTriggers = supportedTriggers
        self.parameters = parameters
        self.performanceClass = performanceClass
        self.requiresCapture = requiresCapture
        self.requires3D = requires3D
    }
}

public struct EffectInvocation: Codable, Sendable {
    public var effectID: EffectID
    public var parameters: [String: EffectValue]
    public var duration: Double
    public var startOffset: Double
}
