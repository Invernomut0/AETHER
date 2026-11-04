import Foundation
import AETHERShared

public actor EffectRegistry: EffectRegistryProtocol {
    private var effects: [EffectID: any WindowEffect] = [:]
    public init() {}

    public func register(_ effect: any WindowEffect) async throws {
        let id = effect.descriptor.id
        guard effects[id] == nil else {
            throw AetherError.invalidState("Effect already registered: \(id.rawValue)")
        }
        effects[id] = effect
    }

    public func descriptor(for id: EffectID) async -> EffectDescriptor? {
        effects[id]?.descriptor
    }

    public func allDescriptors() async -> [EffectDescriptor] {
        effects.values.map(\.descriptor).sorted { $0.name < $1.name }
    }
}
