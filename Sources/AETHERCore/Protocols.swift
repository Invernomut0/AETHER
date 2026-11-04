import Foundation
import AETHERShared

public protocol WindowOrchestrating: Sendable {
    func refreshWindows() async throws -> [WindowDescriptor]
    func handle(_ event: AetherEvent) async
}

public protocol PermissionChecking: Sendable {
    func accessibilityGranted() async -> Bool
    func screenRecordingGranted() async -> Bool
}

public protocol Recovering: Sendable {
    func recoverAllTransientResources() async
}
