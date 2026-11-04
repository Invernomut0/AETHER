import Foundation
import AETHERShared

public struct EffectContext: Sendable {
    public let window: RuntimeWindowHandle?
    public let timestamp: Double
    public let quality: QualityPreset
}

public protocol WindowEffect: Sendable {
    var descriptor: EffectDescriptor { get }
    func prepare(context: EffectContext) async throws
    func update(progress: Double, context: EffectContext)
    func finish(context: EffectContext)
}

public protocol EffectRegistryProtocol: Sendable {
    func register(_ effect: any WindowEffect) async throws
    func descriptor(for id: EffectID) async -> EffectDescriptor?
    func allDescriptors() async -> [EffectDescriptor]
}
