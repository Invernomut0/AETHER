import Foundation
import ScreenCaptureKit
import CoreMedia
import CoreVideo
import CoreGraphics
import Carbon
import AETHERShared

/// Immutable SCK snapshot, transferred once from its completion handler to the owner queue.
/// No other consumer reads it; derived SCWindow/filter/stream references stay on that queue.
private struct ContentTransfer: @unchecked Sendable {
    let content: SCShareableContent
}

/// Mutable SDK state is queue-confined; the active flag is separately locked. Only Data-backed
/// Sendable frames escape. The unchecked conformance never permits direct access to SDK objects.
final class CaptureStreamLease: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    let frames: AsyncThrowingStream<CapturedFrame, any Error>
    private let continuation: AsyncThrowingStream<CapturedFrame, any Error>.Continuation
    private let id: CaptureSessionID
    private let queue = DispatchQueue(label: "com.aether.capture.output", qos: .userInitiated)
    private let activeLock = NSLock()
    private var active = false // activeLock only
    private var stream: SCStream? // queue only, as are all following fields
    private var stopping = false
    private var startPending = false
    private var startDeadline: CallbackDeadline<Void>?
    private var stopPending = false
    private var stopWaiters: [CallbackDeadline<Void>] = []

    var isActive: Bool {
        activeLock.lock()
        defer { activeLock.unlock() }
        return active
    }

    init(id: CaptureSessionID) {
        self.id = id
        (frames, continuation) = AsyncThrowingStream.makeStream(bufferingPolicy: .bufferingNewest(1))
        super.init()
    }

    func start(request: CaptureRequest) async throws {
        let deadline = CallbackDeadline<Void>()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (waiter: CheckedContinuation<Void, any Error>) in
                guard deadline.install(waiter, timeout: .seconds(5)) else { return }
                queue.async {
                    guard !self.stopping else {
                        deadline.finish(.failure(CancellationError()))
                        return
                    }
                    self.startDeadline = deadline
                }
                SCShareableContent.getExcludingDesktopWindows(true, onScreenWindowsOnly: true) { content, error in
                    let failure = error.map { AetherError.operationFailed("Shareable content: \($0.localizedDescription)") }
                    let transfer = content.map { ContentTransfer(content: $0) }
                    self.queue.async {
                        guard !self.stopping else { return }
                        do {
                            if let failure { throw failure }
                            guard let transfer else { throw AetherError.resourceUnavailable("No shareable content") }
                            try self.configure(content: transfer.content, request: request, deadline: deadline)
                        } catch {
                            self.startDeadline = nil
                            deadline.finish(.failure(error))
                        }
                    }
                }
            }
        } onCancel: { deadline.finish(.failure(CancellationError())) }
    }

    /// Cleanup does not inherit caller cancellation; its own deadline bounds waiting.
    func stop() async throws {
        let deadline = CallbackDeadline<Void>()
        try await withCheckedThrowingContinuation { (waiter: CheckedContinuation<Void, any Error>) in
            deadline.install(waiter, timeout: .seconds(3))
            queue.async { self.requestStop(waiter: deadline) }
        }
    }

    private func configure(content: SCShareableContent, request: CaptureRequest,
                           deadline: CallbackDeadline<Void>) throws {
        guard CGPreflightScreenCaptureAccess(), !IsSecureEventInputEnabled(),
              let window = content.windows.first(where: { $0.windowID == request.handle.windowID.rawValue }),
              let app = window.owningApplication, app.processID == request.handle.processID,
              app.bundleIdentifier == request.bundleIdentifier, window.isOnScreen,
              CapturePrivacyPolicy.allows(bundleIdentifier: app.bundleIdentifier,
                                          excludedBundleIDs: request.excludedBundleIDs),
              abs(window.frame.minX - request.frame.cgRect.minX) <= 1,
              abs(window.frame.minY - request.frame.cgRect.minY) <= 1,
              abs(window.frame.width - request.frame.cgRect.width) <= 1,
              abs(window.frame.height - request.frame.cgRect.height) <= 1 else {
            throw AetherError.permissionDenied("Selected window changed or is not eligible for capture")
        }
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let size = filter.contentRect.size
        let scale = Double(filter.pointPixelScale)
        guard size.width.isFinite, size.height.isFinite, scale.isFinite,
              size.width > 0, size.height > 0, scale > 0 else {
            throw AetherError.invalidState("Capture filter has invalid dimensions")
        }
        let factor = min(scale, Double(BGRAPixelFrame.maximumDimension) / max(size.width, size.height))
        let configuration = SCStreamConfiguration()
        configuration.width = max(1, Int((size.width * factor).rounded(.down)))
        configuration.height = max(1, Int((size.height * factor).rounded(.down)))
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        configuration.queueDepth = 3
        configuration.showsCursor = false
        configuration.capturesAudio = false
        configuration.ignoreShadowsSingleWindow = true
        configuration.scalesToFit = true
        let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        self.stream = stream
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: queue)
        startPending = true
        stream.startCapture { error in
            let failure = error.map { AetherError.operationFailed("Stream start: \($0.localizedDescription)") }
            self.queue.async {
                self.startPending = false
                self.startDeadline = nil
                if self.stopping {
                    self.requestStop(waiter: nil)
                } else if let failure {
                    deadline.finish(.failure(failure))
                } else {
                    self.setActive(true)
                    if !deadline.finish(.success(())) { self.requestStop(waiter: nil) }
                }
            }
        }
    }

    private func requestStop(waiter: CallbackDeadline<Void>?) {
        stopping = true
        // Stop must settle Start even before enumeration or stream startup completes.
        // This closes only the Swift waiter; pending SDK resources still require confirmed stop.
        startDeadline?.finish(.failure(CancellationError()))
        startDeadline = nil
        setActive(false)
        continuation.finish()
        if let waiter { stopWaiters.append(waiter) }
        guard let stream else { finishStop(nil); return }
        guard !stopPending else { return }
        stopPending = true
        stream.stopCapture { error in
            let failure = error.map { AetherError.operationFailed("Stream stop: \($0.localizedDescription)") }
            // Apple defines this exact domain/code as already stopped or nonexistent. A closed
            // capture target can stop SCK before our request. No string matching or blanket ignore.
            let alreadyStopped = error.map { error in
                let error = error as NSError
                return error.domain == SCStreamErrorDomain
                    && error.code == SCStreamError.Code.attemptToStopStreamState.rawValue
            } ?? false
            self.queue.async {
                self.stopPending = false
                // Never release while a late startup could still make the stream active.
                if let failure, !(alreadyStopped && !self.startPending) {
                    self.finishStop(failure)
                    return
                }
                // A late start completion issues stop again before releasing the stream.
                if !self.startPending {
                    var removalFailure: AetherError?
                    do { try self.stream?.removeStreamOutput(self, type: .screen) }
                    catch { removalFailure = .operationFailed("Output removal: \(error.localizedDescription)") }
                    self.stream = nil
                    self.finishStop(removalFailure)
                }
            }
        }
    }

    private func finishStop(_ error: AetherError?) {
        let result: Result<Void, any Error> = error.map { .failure($0) } ?? .success(())
        stopWaiters.forEach { $0.finish(result) }
        stopWaiters.removeAll()
    }

    private func setActive(_ value: Bool) {
        activeLock.lock()
        active = value
        activeLock.unlock()
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard !stopping, type == .screen, sampleBuffer.isValid,
              let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
              let status = attachments.first?[.status] as? Int,
              status == SCFrameStatus.complete.rawValue,
              let image = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard CGPreflightScreenCaptureAccess(), !IsSecureEventInputEnabled() else {
            continuation.finish(throwing: AetherError.permissionDenied("Screen Recording revoked or secure input enabled"))
            requestStop(waiter: nil)
            return
        }
        let width = CVPixelBufferGetWidth(image)
        let height = CVPixelBufferGetHeight(image)
        let stride = CVPixelBufferGetBytesPerRow(image)
        guard width > 0, height > 0, width <= BGRAPixelFrame.maximumDimension,
              height <= BGRAPixelFrame.maximumDimension,
              stride >= width * 4, stride <= BGRAPixelFrame.maximumDimension * 4 + 4096,
              CVPixelBufferGetPixelFormatType(image) == kCVPixelFormatType_32BGRA,
              CVPixelBufferLockBaseAddress(image, .readOnly) == kCVReturnSuccess else { return }
        defer { CVPixelBufferUnlockBaseAddress(image, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(image) else { return }
        do {
            let pixels = try BGRAPixelFrame(width: width, height: height, bytesPerRow: stride,
                                           bytes: Data(bytes: base, count: stride * height))
            let metadata = CapturedFrameMetadata(timestamp: sampleBuffer.presentationTimeStamp.seconds,
                                                 width: width, height: height, isComplete: true)
            continuation.yield(CapturedFrame(sessionID: id, metadata: metadata, pixels: pixels,
                                             receivedAtUptime: ProcessInfo.processInfo.systemUptime))
        } catch {
            continuation.finish(throwing: error)
            requestStop(waiter: nil)
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: any Error) {
        let failure = AetherError.operationFailed("Capture interrupted: \(error.localizedDescription)")
        queue.async {
            guard !self.stopping else { return }
            self.continuation.finish(throwing: failure)
            self.requestStop(waiter: nil)
        }
    }
}