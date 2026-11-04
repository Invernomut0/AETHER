import Foundation
import AETHERShared

public actor EventBus {
    private var continuations: [UUID: AsyncStream<AetherEvent>.Continuation] = [:]

    public init() {}

    public func stream() -> AsyncStream<AetherEvent> {
        let id = UUID()
        return AsyncStream { continuation in
            continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.remove(id) }
            }
        }
    }

    public func publish(_ event: AetherEvent) {
        for continuation in continuations.values {
            continuation.yield(event)
        }
    }

    private func remove(_ id: UUID) {
        continuations.removeValue(forKey: id)
    }
}
