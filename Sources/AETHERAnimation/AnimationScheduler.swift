import Foundation
import AETHERShared

public actor AnimationScheduler: AnimationExecuting {
    private var active: Set<AnimationID> = []

    public init() {}

    public func play(_ sequence: AnimationSequence) async throws -> AnimationID {
        guard sequence.duration >= 0 else {
            throw AetherError.invalidState("Animation duration cannot be negative")
        }
        let id = sequence.id
        active.insert(id)
        // Timeline execution and render binding are implemented in M3.
        // Do not report completion until the render scheduler is connected.
        return id
    }

    public func cancel(_ id: AnimationID) async { active.remove(id) }
    public func pause(_ id: AnimationID) async {}
    public func resume(_ id: AnimationID) async {}
}
