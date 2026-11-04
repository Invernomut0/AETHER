import Foundation

public enum InterpolationType: String, Codable, Sendable {
    case linear, easeIn, easeOut, easeInOut, cubicBezier, spring
}

public enum AnimationTarget: Codable, Sendable {
    case opacity, scale, rotation, position, size, custom(String)
}

public struct AnimationKeyframe: Codable, Sendable {
    public var time: Double
    public var value: EffectValue
    public var interpolation: InterpolationType
}

public struct AnimationTrack: Codable, Sendable {
    public var target: AnimationTarget
    public var keyframes: [AnimationKeyframe]
}

public enum CompletionBehavior: String, Codable, Sendable {
    case restoreNative, keepFinalState, handoffToNext, noOp
}

public struct AnimationSequence: Codable, Sendable {
    public var id: AnimationID
    public var name: String
    public var duration: Double
    public var effects: [EffectInvocation]
    public var tracks: [AnimationTrack]
    public var completionBehavior: CompletionBehavior
}
