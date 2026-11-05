import Foundation
import CoreGraphics
import Carbon
import AETHERShared
import AETHERWindowManager
import AETHERCapture
import AETHERRendering

/// Snapshot is a single captured image; live explicitly opens a continuous recording stream.
public enum WindowPreviewMode: Sendable {
    case snapshot
    case live
}

public struct WindowPreviewReport: Sendable {
    public let mode: WindowPreviewMode
    public let framesPresented: UInt64
    public let overlayRemoved: Bool
    public let nativeFrameUnchanged: Bool
}

/// A bounded diagnostic transaction, not native-window replacement or an animation engine.
/// AppKit/Metal stay MainActor; capture sends only copied pixels. No native writes are performed.
@MainActor
public final class WindowPreviewCoordinator {
    private let windows: NativeWindowService
    private let capture = ScreenCaptureCoordinator()
    private var renderer: MetalOverlayPresenter?
    private var running = false
    private var stopRequested = false
    public private(set) var framesPresented: UInt64 = 0
    public var isOverlayVisible: Bool { renderer?.diagnostics().isVisible ?? false }

    public init(windows: NativeWindowService) { self.windows = windows }

    /// Stop/dismissal cancels the caller's structured task; this also hides its overlay immediately.
    public func removeOverlay() {
        stopRequested = true
        renderer?.remove()
    }

    public func preview(_ handle: RuntimeWindowHandle, configuration: AetherConfiguration,
                        duration: Duration = .seconds(5), mode: WindowPreviewMode = .snapshot) async throws -> WindowPreviewReport {
        try Task.checkCancellation()
        guard !running else { throw AetherError.invalidState("Another preview is still cleaning up") }
        guard configuration.effectsEnabled, duration > .zero, duration <= .seconds(5) else {
            throw AetherError.invalidState("Preview is disabled or exceeds the five-second safety limit")
        }
        running = true
        stopRequested = false
        framesPresented = 0
        defer { running = false }
        let original = try await windows.validatedWindow(handle)
        let request = try CaptureRequest(window: original, excludedBundleIDs: configuration.captureExcludedBundleIDs)
        // A passive permission check in capture runs before any SCK enumeration.
        try await capture.stopAllCaptures()
        if mode == .snapshot {
            return try await previewSnapshot(request, original: original, duration: duration)
        }
        let session = try await capture.startCapture(request: request)
        var outcome: Result<Void, any Error>
        do {
            guard !stopRequested else { throw CancellationError() }
            let current = try await windows.validatedWindow(handle)
            try requireUnchanged(current, original: original)
            if renderer == nil { renderer = MetalOverlayPresenter() }
            framesPresented = 0
            let stream = try await capture.frames(sessionID: session)
            try await display(stream, handle: handle, original: original, duration: duration)
            outcome = .success(())
        } catch { outcome = .failure(error) }
        renderer?.remove()
        do { try await capture.stopCaptureReportingErrors(sessionID: session) }
        catch { outcome = .failure(AetherError.operationFailed("Capture cleanup failed: \(error)")) }
        try outcome.get()
        let reconciled = try await windows.validatedWindow(handle)
        try requireUnchanged(reconciled, original: original)
        return WindowPreviewReport(mode: .live, framesPresented: framesPresented,
                                   overlayRemoved: renderer?.diagnostics().isVisible == false,
                                   nativeFrameUnchanged: true)
    }

    /// Capture once, release all screenshot SDK ownership, then hold that explicitly static image.
    /// No timer refreshes screenshots and no SCStream runs behind the normal preview.
    private func previewSnapshot(_ request: CaptureRequest, original: WindowDescriptor,
                                 duration: Duration) async throws -> WindowPreviewReport {
        var outcome: Result<Void, any Error>
        do {
            let frame = try await capture.captureSnapshot(request: request)
            try Task.checkCancellation()
            guard !stopRequested else { throw CancellationError() }
            let current = try await windows.validatedWindow(request.handle)
            try requireUnchanged(current, original: original)
            guard ProcessInfo.processInfo.systemUptime - frame.receivedAtUptime <= 1,
                  let rect = original.frame?.cgRect else {
                throw AetherError.timeout("Snapshot was stale before presentation")
            }
            if renderer == nil { renderer = MetalOverlayPresenter() }
            guard let renderer else { throw AetherError.resourceUnavailable("Metal preview unavailable") }
            try await renderer.present(frame.pixels, frame: rect, relativeTo: Int(request.handle.windowID.rawValue))
            guard !stopRequested else { throw CancellationError() }
            framesPresented = 1
            try await monitor(handle: request.handle, original: original, duration: duration)
            outcome = .success(())
        } catch { outcome = .failure(error) }
        renderer?.remove()
        do { try await capture.stopAllCaptures() }
        catch { outcome = .failure(AetherError.operationFailed("Snapshot cleanup failed: \(error)")) }
        try outcome.get()
        let reconciled = try await windows.validatedWindow(request.handle)
        try requireUnchanged(reconciled, original: original)
        return WindowPreviewReport(mode: .snapshot, framesPresented: framesPresented,
                                   overlayRemoved: renderer?.diagnostics().isVisible == false,
                                   nativeFrameUnchanged: true)
    }

    private func display(_ stream: AsyncThrowingStream<CapturedFrame, any Error>,
                         handle: RuntimeWindowHandle, original: WindowDescriptor,
                         duration: Duration) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.consume(stream, handle: handle, original: original)
            }
            group.addTask {
                try await self.monitor(handle: handle, original: original, duration: duration)
            }
            defer { group.cancelAll() }
            try await group.next()
        }
    }

    private func consume(_ stream: AsyncThrowingStream<CapturedFrame, any Error>,
                         handle: RuntimeWindowHandle, original: WindowDescriptor) async throws {
        for try await frame in stream {
            try Task.checkCancellation()
            guard !stopRequested else { throw CancellationError() }
            guard ProcessInfo.processInfo.systemUptime - frame.receivedAtUptime <= 1,
                  let rect = original.frame?.cgRect, let renderer else {
                throw AetherError.timeout("Captured frame is stale or renderer unavailable")
            }
            try await renderer.present(frame.pixels, frame: rect, relativeTo: Int(handle.windowID.rawValue))
            guard !stopRequested else { renderer.remove(); throw CancellationError() }
            framesPresented += 1
        }
        try Task.checkCancellation()
        throw AetherError.operationFailed("Capture ended before the preview completed")
    }

    private func monitor(handle: RuntimeWindowHandle, original: WindowDescriptor,
                         duration: Duration) async throws {
        let clock = ContinuousClock()
        let started = clock.now
        // Both paths validate after capture and before presentation. Do not immediately
        // repeat AX IPC as the first frame becomes visible; native visibility is checked below.
        var nextValidation = started.advanced(by: .milliseconds(500))
        while clock.now - started < duration {
            try Task.checkCancellation()
            guard !stopRequested else { throw CancellationError() }
            guard CGPreflightScreenCaptureAccess(), !IsSecureEventInputEnabled() else {
                removeOverlay()
                throw AetherError.permissionDenied("Recording permission revoked or secure input enabled")
            }
            try requireNativeVisibility(original)
            if framesPresented == 0 && clock.now - started >= .seconds(2) {
                throw AetherError.timeout("No complete fresh frame arrived within two seconds")
            }
            if clock.now >= nextValidation {
                let current = try await windows.validatedWindow(handle)
                try requireUnchanged(current, original: original)
                nextValidation = clock.now.advanced(by: .milliseconds(500))
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        guard framesPresented > 0 else { throw AetherError.timeout("No frame was presented") }
    }

    /// WindowServer can publish minimization before AX becomes responsive during the system
    /// transition. Reject that native state before AX IPC; this never replaces AX generation checks.
    private func requireNativeVisibility(_ original: WindowDescriptor) throws {
        guard let rows = CGWindowListCopyWindowInfo(.optionIncludingWindow, original.id.rawValue) as? [[String: Any]] else {
            throw AetherError.resourceUnavailable("Cannot verify native preview visibility")
        }
        guard rows.count == 1, let row = rows.first,
              (row[kCGWindowNumber as String] as? NSNumber)?.uint32Value == original.id.rawValue,
              (row[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value == original.processID,
              (row[kCGWindowIsOnscreen as String] as? NSNumber)?.boolValue == true else {
            removeOverlay()
            throw AetherError.invalidState("Native window disappeared, became off-screen or changed owner; preview removed")
        }
    }

    private func requireUnchanged(_ current: WindowDescriptor, original: WindowDescriptor) throws {
        guard current.runtimeHandle == original.runtimeHandle, current.isOnScreen, !current.isMinimized,
              let frame = current.frame?.cgRect, let originalFrame = original.frame?.cgRect,
              WindowGeometry.approximatelyEqual(frame, originalFrame) else {
            removeOverlay()
            throw AetherError.invalidState("Native window moved, resized, minimized, disappeared or changed identity; preview removed")
        }
    }
}