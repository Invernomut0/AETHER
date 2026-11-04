import Foundation
import AETHERShared

public struct DeclarativeEffect: WindowEffect {
    public let descriptor: EffectDescriptor
    public init(id: String, name: String, category: EffectCategory,
                trigger: EffectTrigger = .manual, requiresCapture: Bool = true,
                requires3D: Bool = false, performance: PerformanceClass = .medium) {
        descriptor = EffectDescriptor(
            id: EffectID(rawValue: id),
            name: name,
            category: category,
            version: 1,
            supportedTriggers: [trigger],
            parameters: [],
            performanceClass: performance,
            requiresCapture: requiresCapture,
            requires3D: requires3D
        )
    }
    public func prepare(context: EffectContext) async throws {}
    public func update(progress: Double, context: EffectContext) {}
    public func finish(context: EffectContext) {}
}

public enum BuiltinEffects {
    public static let catalog: [DeclarativeEffect] = [
        .init(id: "wobbly", name: "Wobbly", category: .window, requires3D: false),
        .init(id: "genie", name: "Genie", category: .transition),
        .init(id: "morph", name: "Morph", category: .transition),
        .init(id: "fold", name: "Fold", category: .spatial, requires3D: true),
        .init(id: "flip", name: "Flip", category: .spatial, requires3D: true),
        .init(id: "magnet", name: "Magnet", category: .window, requiresCapture: false),
        .init(id: "float", name: "Float", category: .window, requiresCapture: false),
        .init(id: "shatter", name: "Shatter", category: .destruction, performance: .high),
        .init(id: "explode", name: "Explode", category: .destruction, performance: .high),
        .init(id: "dissolve", name: "Dissolve", category: .destruction),
        .init(id: "burn", name: "Burn", category: .destruction, performance: .high),
        .init(id: "portal", name: "Portal", category: .spatial, requires3D: true, performance: .high),
        .init(id: "depth-of-field", name: "Depth of Field", category: .spatial, requires3D: true, performance: .high),
        .init(id: "ripple", name: "Ripple", category: .transition),
        .init(id: "liquid-morph", name: "Liquid Morph", category: .transition, performance: .high),
        .init(id: "workspace-cube", name: "Workspace Cube", category: .environment, requires3D: true),
        .init(id: "orbit", name: "Orbit", category: .environment, requires3D: true),
        .init(id: "gravity", name: "Gravity", category: .environment),
        .init(id: "expose-3d", name: "Exposé 3D", category: .environment, requires3D: true)
    ]
}
