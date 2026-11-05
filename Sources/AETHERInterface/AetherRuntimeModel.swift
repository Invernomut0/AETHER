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
    private var previewCoordinator: WindowPreviewCoordinator?
    private var effectCoordinator: WindowEffectCoordinator?
    public private(set) var windows: [WindowDescriptor] = []
    public private(set) var isWindowOperationRunning = false
    public private(set) var isPreviewRunning = false
    public private(set) var windowMessage: String?

    public init() {
        previewCoordinator = WindowPreviewCoordinator(windows: windowService)
        effectCoordinator = WindowEffectCoordinator(windows: windowService)
    }

    func removePreviewOverlay() {
        previewCoordinator?.removeOverlay()
        effectCoordinator?.removeOverlay()
    }

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
        defer { isWindowOperationRunning = false; isPreviewRunning = false }
        do {
            await refreshPermissions()
            // The external engine owns global drag/capture/parking while active. Discovery is
            // still safe; do not layer an independent mutation or renderer over its transaction.
            if case .refresh = command {
                KinetiqEngineCoordinator.shared.refreshStatus()
            } else if KinetiqEngineCoordinator.shared.isActive {
                throw AetherError.invalidState("Stop Kinetiq in Effects before using AETHER native controls or diagnostic overlays")
            }
            switch command {
            case .refresh: break
            case .focus(let handle): try await windowService.activate(handle)
            case .setFrame(let handle, let frame): try await windowService.setFrame(frame.cgRect, for: handle)
            case .effect(let handle, let kind):
                guard let configuration = await coordinator.currentConfiguration(), let effectCoordinator else {
                    throw AetherError.invalidState("Start AETHER before requesting an effect")
                }
                guard !KinetiqEngineCoordinator.shared.isActive else {
                    throw AetherError.invalidState("Kinetiq became active; stop it before requesting a diagnostic effect")
                }
                isPreviewRunning = true
                let report = try await effectCoordinator.perform(kind, on: handle, configuration: configuration,
                                                                 duration: kind == .wobble ? .seconds(2) : .milliseconds(1100))
                let label = report.nativeWindowClosed ? "Native closure verified · dissolve" : "Wobble preview · native window unchanged"
                windowMessage = "\(label): \(report.framesPresented) GPU-completed frames · overlay removed: \(report.overlayRemoved) · Reduce Motion: \(report.reducedMotion)"
            case .preview(let handle), .livePreview(let handle):
                guard let configuration = await coordinator.currentConfiguration(), let previewCoordinator else {
                    throw AetherError.invalidState("Start AETHER successfully before requesting capture")
                }
                guard !KinetiqEngineCoordinator.shared.isActive else {
                    throw AetherError.invalidState("Kinetiq became active; stop it before requesting a diagnostic preview")
                }
                isPreviewRunning = true
                let mode: WindowPreviewMode
                if case .livePreview = command { mode = .live } else { mode = .snapshot }
                let report = try await previewCoordinator.preview(handle, configuration: configuration, mode: mode)
                let label = report.mode == .snapshot ? "Static snapshot" : "Live recording diagnostic"
                windowMessage = "\(label): \(report.framesPresented) GPU-completed frames · overlay removed: \(report.overlayRemoved) · native frame unchanged: \(report.nativeFrameUnchanged)"
            }
            windows = try await windowService.refresh()
            let resolved = windows.filter { $0.runtimeHandle != nil }.count
            if windowMessage == nil {
                windowMessage = "\(windows.count) native windows · \(resolved) safely correlated · \(windows.count - resolved) read-only"
            }
        } catch is CancellationError {
            windows = []
            windowMessage = "Operation cancelled. Refresh to reconcile native window state."
        } catch {
            windows = []
            windowMessage = "\(error). Refresh to inspect current native state."
        }
    }
}