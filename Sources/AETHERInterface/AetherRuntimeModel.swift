import Foundation
import Observation
import AETHERCore
import AETHERShared
import AETHERWindowManager

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
    private let windowService = NativeWindowService()
    public private(set) var windows: [WindowDescriptor] = []
    public private(set) var isWindowOperationRunning = false
    public private(set) var windowMessage: String?

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

    /// Called by the panel's structured task; dismissal/cancel propagates into native operations.
    func performWindowCommand(_ command: WindowPanelCommand) async {
        guard !isWindowOperationRunning else { return }
        isWindowOperationRunning = true
        windowMessage = nil
        defer { isWindowOperationRunning = false }
        do {
            await refreshPermissions()
            switch command {
            case .refresh: break
            case .focus(let handle): try await windowService.activate(handle)
            case .setFrame(let handle, let frame): try await windowService.setFrame(frame.cgRect, for: handle)
            }
            windows = try await windowService.refresh()
            let resolved = windows.filter { $0.runtimeHandle != nil }.count
            windowMessage = "\(windows.count) native windows · \(resolved) safely correlated · \(windows.count - resolved) read-only"
        } catch is CancellationError {
            windows = []
            windowMessage = "Operation cancelled. Refresh to reconcile native window state."
        } catch {
            windows = []
            windowMessage = "\(error). Refresh to inspect current native state."
        }
    }
}