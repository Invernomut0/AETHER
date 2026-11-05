import Foundation
import ScreenCaptureKit
import CoreGraphics
import CoreVideo
import Carbon
import AETHERShared

/// Callback-owned immutable references handed off exactly once to the serial owner queue.
/// These wrappers are private: neither SDK objects nor their accessors escape to an actor.
private struct SnapshotContentTransfer: @unchecked Sendable {
    let content: SCShareableContent
}

private struct SnapshotImageTransfer: @unchecked Sendable {
    let image: CGImage
}

/// A one-shot waiter with observable settlement, so a late enumeration cannot start capture.
/// The lock serializes pending-state admission with cancellation/deadline settlement, but
/// never encloses an SDK call: the Swift waiter can settle even if that call returns slowly.
private final class SnapshotWaiter: @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<CapturedFrame, any Error>?
    private var continuation: CheckedContinuation<CapturedFrame, any Error>?
    private var timer: Task<Void, Never>?

    var isPending: Bool {
        lock.lock()
        defer { lock.unlock() }
        return result == nil && continuation != nil
    }

    func install(_ waiter: CheckedContinuation<CapturedFrame, any Error>) -> Bool {
        lock.lock()
        if let result {
            lock.unlock()
            waiter.resume(with: result)
            return false
        }
        guard continuation == nil else {
            lock.unlock()
            waiter.resume(throwing: AetherError.invalidState("Snapshot already has a waiter"))
            return false
        }
        continuation = waiter
        timer = Task.detached { [weak self] in
            do {
                try await Task.sleep(for: .seconds(5))
                self?.finish(.failure(AetherError.timeout("Snapshot exceeded its startup deadline")))
            } catch { /* Settlement cancels the timer. */ }
        }
        lock.unlock()
        return true
    }

    /// Only records queue-owned pending state. Admission winning first commits the SDK call;
    /// Stop/timeout winning first prevents it. The actual call runs immediately outside locks.
    func admit(_ operation: () -> Void) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard result == nil, continuation != nil else { return false }
        operation()
        return true
    }

    @discardableResult
    func finish(_ result: Result<CapturedFrame, any Error>) -> Bool {
        lock.lock()
        guard self.result == nil else { lock.unlock(); return false }
        self.result = result
        let waiter = continuation
        continuation = nil
        let timer = timer
        self.timer = nil
        lock.unlock()
        timer?.cancel()
        waiter?.resume(with: result)
        return true
    }
}

/// Independent single-image implementation. All SDK references and pending-callback state are
/// queue-confined. Only immutable Data-backed frames cross isolation boundaries. The separate
/// state lock protects Stop admission and delivery, never SDK references. A callback retains
/// this owner until its queued completion runs, even after either Swift deadline expires.
final class WindowSnapshotLease: @unchecked Sendable {
    let id: CaptureSessionID
    private let queue = DispatchQueue(label: "com.aether.capture.snapshot", qos: .userInitiated)
    private let stateLock = NSLock()
    private var stopped = false // stateLock only
    private var available = false // stateLock only
    private let captureWaiter = SnapshotWaiter()
    private var enumerationPending = false // queue only, as are all following fields
    private var imagePending = false
    private var contentFilter: SCContentFilter?
    private var configuration: SCStreamConfiguration?
    private var stopWaiters: [CallbackDeadline<Void>] = []

    var isAvailable: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return available && !stopped
    }

    init(id: CaptureSessionID) { self.id = id }

    func capture(request: CaptureRequest) async throws -> CapturedFrame {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { waiter in
                guard captureWaiter.install(waiter) else { return }
                queue.async { self.begin(request: request) }
            }
        } onCancel: {
            self.cancelDelivery()
            self.queue.async { self.finishStopIfConfirmed() }
        }
    }

    /// Stop closes the Swift waiter immediately, including before queue startup. There is no
    /// SDK cancellation API: ownership is released only after BOTH possible callbacks finish.
    /// Cleanup has its own 3s deadline and deliberately ignores caller task cancellation.
    func stop() async throws {
        cancelDelivery()
        let deadline = CallbackDeadline<Void>()
        try await withCheckedThrowingContinuation { (waiter: CheckedContinuation<Void, any Error>) in
            deadline.install(waiter, timeout: .seconds(3))
            queue.async {
                self.stopWaiters.append(deadline)
                self.finishStopIfConfirmed()
            }
        }
    }

    private func cancelDelivery() {
        stateLock.lock()
        stopped = true
        available = false
        stateLock.unlock()
        captureWaiter.finish(.failure(CancellationError()))
    }

    /// Lock order is stateLock then waiter lock. Admission commits pending state atomically;
    /// the API executes outside both locks so cancellation/deadlines remain independent.
    private func admitSDKCall(prepare: () -> Void, operation: () -> Void) -> Bool {
        stateLock.lock()
        let admitted = !stopped && captureWaiter.admit(prepare)
        stateLock.unlock()
        guard admitted else { return false }
        operation()
        return true
    }

    private func begin(request: CaptureRequest) {
        do {
            try validatePolicy(request: request)
            guard admitSDKCall(prepare: {
                enumerationPending = true
            }, operation: {
                SCShareableContent.getExcludingDesktopWindows(true, onScreenWindowsOnly: true) { content, error in
                    let transfer = content.map { SnapshotContentTransfer(content: $0) }
                    let failure = error.map { AetherError.operationFailed("Snapshot content: \($0.localizedDescription)") }
                    self.queue.async {
                        self.enumerationPending = false
                        do {
                            guard self.captureWaiter.isPending else { self.finishStopIfConfirmed(); return }
                            if let failure { throw failure }
                            guard let transfer else { throw AetherError.resourceUnavailable("No snapshot shareable content") }
                            try self.captureImage(content: transfer.content, request: request)
                        } catch {
                            self.captureWaiter.finish(.failure(error))
                            self.finishStopIfConfirmed()
                        }
                    }
                }
            }) else { finishStopIfConfirmed(); return }
        } catch {
            captureWaiter.finish(.failure(error))
            finishStopIfConfirmed()
        }
    }

    /// Only passive permission checks; never requests consent or suppresses system indicators.
    private func validatePolicy(request: CaptureRequest) throws {
        let rect = request.frame.cgRect
        guard request.handle.processID > 0, request.handle.windowID.rawValue != 0,
              rect.minX.isFinite, rect.minY.isFinite, rect.maxX.isFinite, rect.maxY.isFinite,
              rect.width.isFinite, rect.height.isFinite, rect.width > 0, rect.height > 0 else {
            throw AetherError.invalidState("Snapshot requires valid runtime identity and geometry")
        }
        guard CapturePrivacyPolicy.allows(bundleIdentifier: request.bundleIdentifier,
                                          excludedBundleIDs: request.excludedBundleIDs),
              !IsSecureEventInputEnabled(), CGPreflightScreenCaptureAccess() else {
            throw AetherError.permissionDenied("Snapshot blocked by privacy policy, secure input or Screen Recording permission")
        }
    }

    private func captureImage(content: SCShareableContent, request: CaptureRequest) throws {
        try validatePolicy(request: request)
        let matches = content.windows.filter { $0.windowID == request.handle.windowID.rawValue }
        guard matches.count == 1, let window = matches.first,
              let app = window.owningApplication, app.processID == request.handle.processID,
              app.bundleIdentifier == request.bundleIdentifier, window.isOnScreen,
              window.frame == request.frame.cgRect,
              CapturePrivacyPolicy.allows(bundleIdentifier: app.bundleIdentifier,
                                          excludedBundleIDs: request.excludedBundleIDs) else {
            throw AetherError.permissionDenied("Selected snapshot window changed or is not eligible")
        }
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let size = filter.contentRect.size
        let scale = Double(filter.pointPixelScale)
        guard size.width.isFinite, size.height.isFinite, scale.isFinite,
              size.width > 0, size.height > 0, scale > 0 else {
            throw AetherError.invalidState("Snapshot filter has invalid dimensions")
        }
        let factor = min(scale, Double(BGRAPixelFrame.maximumDimension) / max(size.width, size.height))
        let config = SCStreamConfiguration()
        config.width = max(1, min(BGRAPixelFrame.maximumDimension, Int((size.width * factor).rounded(.down))))
        config.height = max(1, min(BGRAPixelFrame.maximumDimension, Int((size.height * factor).rounded(.down))))
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.colorSpaceName = CGColorSpace.sRGB
        config.showsCursor = false
        config.capturesAudio = false
        config.ignoreShadowsSingleWindow = true
        config.scalesToFit = true
        // Recheck immediately before the single screenshot call. Generation belongs to the
        // caller and must also be revalidated externally before/after this asynchronous API.
        try validatePolicy(request: request)
        guard admitSDKCall(prepare: {
            contentFilter = filter
            configuration = config
            imagePending = true
        }, operation: {
            SCScreenshotManager.captureImage(contentFilter: filter, configuration: config) { image, error in
                let transfer = image.map { SnapshotImageTransfer(image: $0) }
                let failure = error.map { AetherError.operationFailed("Snapshot image: \($0.localizedDescription)") }
                self.queue.async {
                    self.imagePending = false
                    do {
                        guard self.captureWaiter.isPending else { self.finishStopIfConfirmed(); return }
                        if let failure { throw failure }
                        try self.validatePolicy(request: request)
                        guard let transfer else { throw AetherError.resourceUnavailable("No snapshot image") }
                        let frame = try self.copyFrame(image: transfer.image)
                        // SDK has completed; release its inputs on the owner queue BEFORE
                        // resuming Swift. No screenshot/SDK reference is kept in CapturedFrame.
                        self.contentFilter = nil
                        self.configuration = nil
                        self.stateLock.lock()
                        self.available = !self.stopped
                        self.stateLock.unlock()
                        if !self.captureWaiter.finish(.success(frame)) { self.cancelDelivery() }
                    } catch {
                        self.captureWaiter.finish(.failure(error))
                    }
                    self.finishStopIfConfirmed()
                }
            }
        }) else { finishStopIfConfirmed(); return }
    }

    /// Converts on the owner queue to premultiplied BGRA8 in sRGB. Little-endian 32-bit
    /// premultiplied-first gives B,G,R,A byte order; the context/pointer never outlive the copy.
    private func copyFrame(image: CGImage) throws -> CapturedFrame {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0, width <= BGRAPixelFrame.maximumDimension,
              height <= BGRAPixelFrame.maximumDimension,
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            throw AetherError.invalidState("Invalid or oversized snapshot image")
        }
        let stride = width * 4
        var bytes = Data(count: stride * height)
        try bytes.withUnsafeMutableBytes { buffer in
            guard let base = buffer.baseAddress,
                  let context = CGContext(data: base, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: stride, space: colorSpace,
                                          bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue
                                              | CGImageAlphaInfo.premultipliedFirst.rawValue) else {
                throw AetherError.resourceUnavailable("Cannot create snapshot BGRA context")
            }
            context.setBlendMode(.copy)
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        let pixels = try BGRAPixelFrame(width: width, height: height, bytesPerRow: stride, bytes: bytes)
        let uptime = ProcessInfo.processInfo.systemUptime
        // CGImage has no presentation timestamp; timestamp explicitly represents receipt uptime.
        let metadata = CapturedFrameMetadata(timestamp: uptime, width: width, height: height, isComplete: true)
        return CapturedFrame(sessionID: id, metadata: metadata, pixels: pixels, receivedAtUptime: uptime)
    }

    private func finishStopIfConfirmed() {
        guard !enumerationPending, !imagePending else { return }
        contentFilter = nil
        configuration = nil
        stopWaiters.forEach { $0.finish(.success(())) }
        stopWaiters.removeAll()
    }
}