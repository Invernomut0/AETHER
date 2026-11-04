import Foundation
import CoreGraphics
import Carbon
import OSLog
import AETHERShared

/// On-demand single-session owner. ScreenCaptureKit objects live only on the lease's serial queue.
public actor ScreenCaptureCoordinator: WindowCapturing {
    private var sessions: [CaptureSessionID: CaptureStreamLease] = [:]
    private let log = Logger(subsystem: "com.aether.desktop", category: "capture")

    public init() {}

    /// ID-only capture is deliberately rejected: a recycled CGWindowID is not identity.
    public func startCapture(windowID: WindowID) async throws -> CaptureSessionID {
        throw AetherError.unsupported("Use a validated runtime handle through CaptureRequest, not a window ID alone")
    }

    public func startCapture(request: CaptureRequest) async throws -> CaptureSessionID {
        try Task.checkCancellation()
        guard CapturePrivacyPolicy.allows(bundleIdentifier: request.bundleIdentifier,
                                          excludedBundleIDs: request.excludedBundleIDs),
              !IsSecureEventInputEnabled() else {
            throw AetherError.permissionDenied("Capture blocked by application exclusion or secure input")
        }
        guard CGPreflightScreenCaptureAccess() else {
            throw AetherError.permissionDenied("Screen Recording must be granted explicitly in System Settings; restart if requested")
        }
        guard sessions.isEmpty else { throw AetherError.invalidState("Another capture session is still owned") }
        let id = CaptureSessionID()
        let lease = CaptureStreamLease(id: id)
        sessions[id] = lease
        do {
            try await lease.start(request: request)
            try Task.checkCancellation()
            log.info("Selected-window capture started")
            return id
        } catch {
            do { try await lease.stop() }
            catch { throw AetherError.operationFailed("Capture startup cleanup unconfirmed; retry Stop before another capture: \(error)") }
            sessions.removeValue(forKey: id)
            throw error
        }
    }

    public func frames(sessionID: CaptureSessionID) throws -> AsyncThrowingStream<CapturedFrame, any Error> {
        guard let lease = sessions[sessionID] else { throw AetherError.notFound("Capture session not found") }
        return lease.frames
    }

    public func stopCaptureReportingErrors(sessionID: CaptureSessionID) async throws {
        guard let lease = sessions[sessionID] else { return }
        try await lease.stop()
        sessions.removeValue(forKey: sessionID)
        log.info("Selected-window capture stopped")
    }

    /// Retry cleanup after a timeout; no new session can start until all leases confirm stop.
    public func stopAllCaptures() async throws {
        for id in Array(sessions.keys) { try await stopCaptureReportingErrors(sessionID: id) }
    }

    public func stopCapture(sessionID: CaptureSessionID) async {
        do { try await stopCaptureReportingErrors(sessionID: sessionID) }
        catch { log.error("Capture stop failed: \(String(describing: error), privacy: .public)") }
    }

    public func isCapturing(sessionID: CaptureSessionID) -> Bool {
        sessions[sessionID]?.isActive ?? false
    }
}
