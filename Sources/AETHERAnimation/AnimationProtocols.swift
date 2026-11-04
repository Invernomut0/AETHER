import Foundation
import AETHERShared

public protocol AnimationExecuting: Sendable {
    func play(_ sequence: AnimationSequence) async throws -> AnimationID
    func cancel(_ id: AnimationID) async
    func pause(_ id: AnimationID) async
    func resume(_ id: AnimationID) async
}
