import Foundation
import Observation
import AETHERCore

/// App-owned composition root for the M0 lifecycle and passive permission diagnostics.
@MainActor
@Observable
public final class AetherRuntimeModel {
    public private(set) var isStarting = false
    public private(set) var isRunning = false
    public private(set) var accessibilityGranted = false
    public private(set) var screenRecordingGranted = false
    public private(set) var schemaVersion: Int?
    public private(set) var errorMessage: String?
    private let coordinator = AetherCoordinator()
    private let permissions = PermissionCoordinator()

    public init() {}

    public func start() async {
        guard !isStarting, !isRunning else { return }
        isStarting = true
        errorMessage = nil
        defer { isStarting = false }
        do {
            try await coordinator.start()
            schemaVersion = await coordinator.currentConfiguration()?.schemaVersion
            isRunning = await coordinator.status()
            await refreshPermissions()
        } catch is CancellationError {
            await coordinator.stop()
            isRunning = false
        } catch {
            errorMessage = "Startup failed: \(error). Configuration was not reset. Repair it and retry."
            isRunning = false
        }
    }

    public func refreshPermissions() async {
        accessibilityGranted = await permissions.accessibilityGranted()
        screenRecordingGranted = await permissions.screenRecordingGranted()
    }

    public func requestAccessibility() async {
        _ = permissions.accessibilityTrusted(prompt: true)
        await refreshPermissions()
    }

    public func requestScreenRecording() async {
        _ = permissions.requestScreenCaptureAccess()
        await refreshPermissions()
    }
}