import Foundation
import Testing
import AppKit
import CoreGraphics
import ApplicationServices
import Carbon
import AETHERShared
@testable import AETHERCapture
import AETHERWindowManager
import AETHERCore

private let runCaptureIntegration = ProcessInfo.processInfo.environment["AETHER_RUN_CAPTURE_INTEGRATION"] == "1"
private let runReadOnlyWindowBoundaries = AXIsProcessTrusted() && !IsSecureEventInputEnabled()

@MainActor
@Suite("Capture pipeline policy and live boundaries", .serialized)
struct CapturePipelineTests {
    private static let fixtureBundleIdentifier = "com.aether.testlab"
    private static let fixtureTitles = ["M1 Fixture Resizable A", "M1 Fixture Resizable B"]

    @Test("CapturePrivacyPolicy blocks credential bundle IDs and live exclusions")
    func capturePrivacyPolicyUsesRealBundleIdentifiers() throws {
        let credentials = Set(CapturePrivacyPolicy.credentialBundleIDs.map { $0.lowercased() })
        for bundleID in CapturePrivacyPolicy.credentialBundleIDs {
            #expect(CapturePrivacyPolicy.allows(bundleIdentifier: bundleID, excludedBundleIDs: []) == false)
            #expect(CapturePrivacyPolicy.allows(bundleIdentifier: "\(bundleID).helper", excludedBundleIDs: []) == false)
        }

        let liveBundleIdentifiers = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        let liveNonCredential = try #require(
            liveBundleIdentifiers.sorted().first(where: { bundleID in
                let normalized = bundleID.lowercased()
                return !credentials.contains { normalized == $0 || normalized.hasPrefix($0 + ".") }
            }),
            "No non-credential running bundle identifier was found from NSWorkspace"
        )

        #expect(CapturePrivacyPolicy.allows(bundleIdentifier: liveNonCredential, excludedBundleIDs: []) == true)
        #expect(CapturePrivacyPolicy.allows(bundleIdentifier: liveNonCredential, excludedBundleIDs: [liveNonCredential]) == false)
        #expect(CapturePrivacyPolicy.allows(bundleIdentifier: "\(liveNonCredential).helper", excludedBundleIDs: [liveNonCredential]) == false)
    }

    @Test("CaptureRequest validates runtime-handle and on-screen requirements from live descriptors")
    func captureRequestValidationFromRealDiscovery() async throws {
        let service = NativeWindowService()
        let descriptors = try await service.refresh()
        #expect(!descriptors.isEmpty)
        for descriptor in descriptors {
            let eligible = descriptor.runtimeHandle != nil && descriptor.frame != nil
                && !(descriptor.bundleIdentifier ?? "").isEmpty && descriptor.isOnScreen && !descriptor.isMinimized
            if eligible {
                let request = try CaptureRequest(window: descriptor, excludedBundleIDs: [])
                #expect(request.handle == descriptor.runtimeHandle)
                #expect(request.frame == descriptor.frame)
            } else {
                try expectAetherError(.unsupported) {
                    _ = try CaptureRequest(window: descriptor, excludedBundleIDs: [])
                }
            }
        }
    }

    @Test("ID-only capture start is unsupported for a real discovered window ID")
    func idOnlyCaptureIsUnsupported() async throws {
        let descriptor = try #require(try await NativeWindowService().refresh().first,
                                      "No live window descriptor discovered")
        let coordinator = ScreenCaptureCoordinator()
        try await expectAetherError(.unsupported) {
            _ = try await coordinator.startCapture(windowID: descriptor.id)
        }
    }

    @Test("startCapture(request:) honors pre-cancellation using a live request", .enabled(if: runReadOnlyWindowBoundaries))
    func startCaptureHonorsPreCancellationWithLiveRequest() async throws {
        let service = NativeWindowService()
        guard let request = try await makeLiveCaptureRequest(using: service) else {
            print("CapturePipelineTests: pre-cancel boundary executed read-only because no capture-eligible runtime handle was discovered.")
            return
        }

        let coordinator = ScreenCaptureCoordinator()
        let cancelled = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await coordinator.startCapture(request: request)
        }

        await #expect(throws: CancellationError.self) {
            _ = try await cancelled.value
        }
    }

    @Test("startCapture(request:) respects passive Screen Recording denial without prompting", .enabled(if: runReadOnlyWindowBoundaries && !CGPreflightScreenCaptureAccess()))
    func startCapturePermissionBoundaryWithoutPrompt() async throws {
        guard CGPreflightScreenCaptureAccess() == false else {
            print("CapturePipelineTests: Screen Recording already granted; passive-denial boundary is not applicable.")
            return
        }

        let service = NativeWindowService()
        guard let request = try await makeLiveCaptureRequest(using: service) else {
            print("CapturePipelineTests: passive-denial boundary executed read-only because no capture-eligible runtime handle was discovered.")
            return
        }

        let before = CGPreflightScreenCaptureAccess()
        let coordinator = ScreenCaptureCoordinator()
        try await expectAetherError(.permissionDenied) {
            _ = try await coordinator.startCapture(request: request)
        }
        let after = CGPreflightScreenCaptureAccess()

        #expect(before == false)
        #expect(after == false)
    }

    @Test("Core preview rejects Recording denial before creating an overlay", .enabled(if: runReadOnlyWindowBoundaries && !CGPreflightScreenCaptureAccess()))
    func previewPermissionDenialNeverCreatesOverlay() async throws {
        guard !CGPreflightScreenCaptureAccess() else { return }
        let service = NativeWindowService()
        guard let request = try await makeLiveCaptureRequest(using: service) else {
            print("Core denial path not exercised: no live registered window available.")
            return
        }
        let current = try await service.validatedWindow(request.handle)
        #expect(current.runtimeHandle == request.handle)
        let preview = WindowPreviewCoordinator(windows: service)
        try await expectAetherError(.permissionDenied) {
            _ = try await preview.preview(request.handle, configuration: .default)
        }
        #expect(!preview.isOverlayVisible)
        #expect(preview.framesPresented == 0)
        preview.removeOverlay()
        preview.removeOverlay()
    }

    @Test("CallbackDeadline resumes via real DispatchQueue callback")
    func callbackDeadlineCompletesFromDispatchCallback() async throws {
        let deadline = CallbackDeadline<TimeInterval>()
        let startedUptime = ProcessInfo.processInfo.systemUptime

        let completedUptime = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TimeInterval, any Error>) in
            let installed = deadline.install(continuation, timeout: .seconds(1))
            #expect(installed)
            DispatchQueue.global(qos: .userInitiated).async {
                _ = deadline.finish(.success(ProcessInfo.processInfo.systemUptime))
            }
        }

        #expect(completedUptime >= startedUptime)
    }

    @Test("CallbackDeadline enforces tiny timeout when callback never completes")
    func callbackDeadlineTimesOut() async throws {
        let deadline = CallbackDeadline<Void>()
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                let installed = deadline.install(continuation, timeout: .milliseconds(5))
                #expect(installed)
            }
            throw CapturePipelineAssertionError(message: "Expected timeout, but continuation completed successfully")
        } catch let error as AetherError {
            guard case .timeout = error else {
                throw CapturePipelineAssertionError(message: "Expected AetherError.timeout, got \(error)")
            }
        }
    }

    @Test("CallbackDeadline supports explicit cancellation completion")
    func callbackDeadlineCancellationPath() async {
        let deadline = CallbackDeadline<Void>()
        let cancelled = Task {
            try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                    let installed = deadline.install(continuation, timeout: .seconds(1))
                    #expect(installed)
                    withUnsafeCurrentTask { $0?.cancel() }
                }
            } onCancel: {
                _ = deadline.finish(.failure(CancellationError()))
            }
        }

        await #expect(throws: CancellationError.self) {
            _ = try await cancelled.value
        }
    }

    @Test("CallbackDeadline rejects late completion and pre-cancelled installation")
    func callbackDeadlineRejectsLateAndPreCancelledCallbacks() async {
        let deadline = CallbackDeadline<TimeInterval>()
        #expect(deadline.finish(.failure(CancellationError())))
        #expect(!deadline.finish(.success(ProcessInfo.processInfo.systemUptime)))
        await #expect(throws: CancellationError.self) {
            try await withCheckedThrowingContinuation { (waiter: CheckedContinuation<TimeInterval, any Error>) in
                #expect(!deadline.install(waiter, timeout: .seconds(1)))
            }
        }
    }

    @Test("Idle capture cleanup is idempotent and never requires consent")
    func idleCleanupIsIdempotent() async throws {
        let capture = ScreenCaptureCoordinator()
        #expect(await capture.ownedSessionIDs.isEmpty)
        try await capture.stopAllCaptures()
        try await capture.stopAllCaptures()
        #expect(await capture.ownedSessionIDs.isEmpty)
    }

    @Test("Live preview integration presents fresh frames and removes overlay", .enabled(if: runCaptureIntegration))
    func livePreviewIntegrationWithExternalFixture() async throws {
        _ = try #require(CGPreflightScreenCaptureAccess(),
                         "Screen Recording permission must already be granted for opted-in live integration")
        _ = try #require(AXIsProcessTrusted(),
                         "Accessibility permission is required for opted-in live integration")
        _ = try #require(
            NSRunningApplication.runningApplications(withBundleIdentifier: Self.fixtureBundleIdentifier)
                .first(where: { !$0.isTerminated }),
            "Launch external Test Lab fixtures (bundle \(Self.fixtureBundleIdentifier))"
        )

        let service = NativeWindowService()
        let target = try await requireFixtureDescriptor(using: service)

        let handle = try #require(target.runtimeHandle)
        let originalFrame = try #require(target.frame?.cgRect)
        let frontmostBefore = NSWorkspace.shared.frontmostApplication?.processIdentifier

        let preview = WindowPreviewCoordinator(windows: service)
        let report = try await preview.preview(handle, configuration: .default, duration: .seconds(1), mode: .live)

        #expect(report.framesPresented > 0)
        #expect(report.overlayRemoved)
        #expect(report.nativeFrameUnchanged)

        let cgReadbackFrame = try #require(cgWindowFrame(windowID: target.id),
                                           "CG readback could not find fixture window after preview")
        #expect(WindowGeometry.approximatelyEqual(cgReadbackFrame, originalFrame, tolerance: 2))

        let refreshed = try await service.refresh().first { $0.id == target.id && $0.processID == target.processID }
        let refreshedFrame = try #require(refreshed?.frame?.cgRect)
        #expect(WindowGeometry.approximatelyEqual(refreshedFrame, originalFrame, tolerance: 2))

        let frontmostAfter = NSWorkspace.shared.frontmostApplication?.processIdentifier
        #expect(frontmostAfter == frontmostBefore)
    }

    @Test("Live fixture exclusion policy denies capture startup", .enabled(if: runCaptureIntegration))
    func liveFixtureExclusionPolicyBoundary() async throws {
        _ = try #require(CGPreflightScreenCaptureAccess(),
                         "Screen Recording permission must already be granted for opted-in fixture exclusion test")
        _ = try #require(AXIsProcessTrusted(),
                         "Accessibility permission is required for opted-in fixture exclusion test")

        let service = NativeWindowService()
        let fixture = try await requireFixtureDescriptor(using: service)
        let excludedRequest = try CaptureRequest(window: fixture, excludedBundleIDs: [Self.fixtureBundleIdentifier])

        let coordinator = ScreenCaptureCoordinator()
        try await expectAetherError(.permissionDenied) {
            _ = try await coordinator.startCapture(request: excludedRequest)
        }
    }

    @Test("Live preview cancellation removes overlay and preserves native frame", .enabled(if: runCaptureIntegration))
    func livePreviewCancellationCleansUp() async throws {
        try #require(CGPreflightScreenCaptureAccess(), "Grant Recording explicitly before opting in")
        try #require(AXIsProcessTrusted(), "Grant Accessibility explicitly before opting in")
        let service = NativeWindowService()
        let fixture = try await requireFixtureDescriptor(using: service)
        let handle = try #require(fixture.runtimeHandle)
        let original = try #require(fixture.frame?.cgRect)
        let preview = WindowPreviewCoordinator(windows: service)
        let task = Task { try await preview.preview(handle, configuration: .default, mode: .live) }
        do {
            // Includes the separate five-second capture-start budget and first-frame budget.
            let deadline = ContinuousClock.now.advanced(by: .seconds(8))
            while preview.framesPresented == 0 && ContinuousClock.now < deadline {
                try await Task.sleep(for: .milliseconds(20))
            }
            try #require(preview.framesPresented > 0, "No real capture frame reached Metal")
            task.cancel()
            do {
                _ = try await task.value
                Issue.record("Cancelled preview unexpectedly completed normally")
            } catch is CancellationError {
                // Structured task cancellation.
            } catch let error as AetherError {
                #expect(error == .cancelled)
            }
            #expect(!preview.isOverlayVisible)
            let after = try #require(cgWindowFrame(windowID: fixture.id))
            #expect(WindowGeometry.approximatelyEqual(after, original))
        } catch {
            task.cancel()
            _ = await task.result
            preview.removeOverlay()
            throw error
        }
    }

    @Test("Native target interruption removes the overlay and permits coordinator reuse",
          .enabled(if: runCaptureIntegration), arguments: CaptureInterruption.allCases)
    func liveTargetInterruptionAndRecovery(_ interruption: CaptureInterruption) async throws {
          try await checkTargetInterruption(interruption, mode: .live)
        }

        @Test("Static snapshot target movement/minimization removes the overlay and permits reuse",
            .enabled(if: runCaptureIntegration), arguments: [CaptureInterruption.move, .minimize])
        func liveSnapshotTargetInterruption(_ interruption: CaptureInterruption) async throws {
          try await checkTargetInterruption(interruption, mode: .snapshot)
        }

        private func checkTargetInterruption(_ interruption: CaptureInterruption, mode: WindowPreviewMode) async throws {
        try #require(CGPreflightScreenCaptureAccess(), "Grant Recording explicitly before opting in")
        try #require(AXIsProcessTrusted(), "Grant Accessibility explicitly before opting in")
        let service = NativeWindowService()
        let title = interruption == .close ? "M2 Fixture Capture Disposable" : Self.fixtureTitles[0]
        let fixture = try await requireFixtureDescriptor(using: service, title: title)
        let handle = try #require(fixture.runtimeHandle)
        let original = try #require(fixture.frame?.cgRect)
        // This reference never leaves MainActor and cannot retarget another AX object on PID reuse.
        let element = try fixtureAXWindow(fixture)
        let preview = WindowPreviewCoordinator(windows: service)
        let task = Task { try await preview.preview(handle, configuration: .default, mode: mode) }
        var mutationAttempted = false
        var operationError: (any Error)?
        do {
            let deadline = ContinuousClock.now.advanced(by: .seconds(8))
            while preview.framesPresented == 0 && ContinuousClock.now < deadline {
                try await Task.sleep(for: .milliseconds(20))
            }
            try #require(preview.framesPresented > 0, "No real capture frame reached Metal before mutation")
            let started = ContinuousClock.now
            mutationAttempted = true
            let moved = original.offsetBy(dx: 32, dy: 24)
            switch interruption {
            case .move:
                try await service.setFrame(moved, for: handle)
            case .minimize:
                try setFixtureMinimized(true, element: element)
            case .close:
                let buttonRef = try #require(try fixtureAXAttribute(element, kAXCloseButtonAttribute))
                try #require(CFGetTypeID(buttonRef) == AXUIElementGetTypeID())
                let button = unsafeDowncast(buttonRef, to: AXUIElement.self)
                try #require(AXUIElementSetMessagingTimeout(button, 0.15) == .success)
                try #require(AXUIElementPerformAction(button, kAXPressAction as CFString) == .success)
            }

            let result = await task.result
            switch result {
            case .success:
                Issue.record("Preview completed normally after native target interruption")
            case .failure(let error):
                guard let error = error as? AetherError else { throw error }
                switch error {
                case .invalidState, .notFound:
                    break // Native revalidation observed the changed/disappeared target.
                case .operationFailed(let message) where interruption == .close && message.hasPrefix("Capture interrupted:"):
                    break // SCK can report target closure before the periodic native validation.
                default:
                    throw error // In particular, never accept failed cleanup, timeout or cancellation.
                }
                print("M2 \(mode) \(interruption.rawValue): observed \(error)")
            }
            #expect(ContinuousClock.now - started < .seconds(10))
            #expect(!preview.isOverlayVisible)
            switch interruption {
            case .move:
                let after = try #require(cgWindowFrame(windowID: fixture.id))
                #expect(WindowGeometry.approximatelyEqual(after, moved))
            case .minimize:
                #expect((try fixtureAXAttribute(element, kAXMinimizedAttribute) as? NSNumber)?.boolValue == true)
            case .close:
                let disappearanceDeadline = ContinuousClock.now.advanced(by: .seconds(4))
                while cgWindowFrame(windowID: fixture.id) != nil && ContinuousClock.now < disappearanceDeadline {
                    try await Task.sleep(for: .milliseconds(40))
                }
                #expect(cgWindowFrame(windowID: fixture.id) == nil)
            }

            // Reuse the SAME capture owner and renderer while the native mutation is still in effect.
            let recovery = try await requireFixtureDescriptor(using: service, title: Self.fixtureTitles[1])
            let recoveryHandle = try #require(recovery.runtimeHandle)
            let report = try await preview.preview(recoveryHandle, configuration: .default, duration: .seconds(1), mode: mode)
            #expect(report.framesPresented > 0)
            #expect(report.mode == mode)
            if mode == .snapshot { #expect(report.framesPresented == 1) }
            #expect(report.overlayRemoved && report.nativeFrameUnchanged)
            #expect(!preview.isOverlayVisible)
        } catch { operationError = error }

        task.cancel()
        _ = await task.result
        preview.removeOverlay()
        // Restore only the controlled fixture; never roll back the mutation inside the engine.
        if mutationAttempted && interruption != .close {
            if interruption == .minimize { try setFixtureMinimized(false, element: element) }
            let current = try await requireFixtureDescriptor(using: service, title: title)
            try #require(current.id == fixture.id && current.processID == fixture.processID)
            if interruption == .move {
                try await service.setFrame(original, for: try #require(current.runtimeHandle))
            }
            let restored = try #require(cgWindowFrame(windowID: fixture.id))
            #expect(WindowGeometry.approximatelyEqual(restored, original))
        }
        if let operationError { throw operationError }
    }

    @Test("Cancellation of an observed pending startup releases ownership and permits real capture",
          .enabled(if: runCaptureIntegration))
    func liveStartupCancellationAndReuse() async throws {
        try #require(CGPreflightScreenCaptureAccess() && AXIsProcessTrusted(), "Pre-granted Recording/AX required")
        let service = NativeWindowService()
        let fixture = try await requireFixtureDescriptor(using: service, title: Self.fixtureTitles[0])
        let handle = try #require(fixture.runtimeHandle)
        let request = try CaptureRequest(window: try await service.validatedWindow(handle), excludedBundleIDs: [])
        let capture = ScreenCaptureCoordinator()
        let startup = Task { try await capture.startCapture(request: request) }
        do {
            // Observe an actual registered lease, not a guessed delay or pre-cancelled task.
            let pendingID = try await requirePendingCaptureID(in: capture)
            startup.cancel()
            switch await startup.result {
            case .failure(let error) where error is CancellationError:
                break
            case .failure(let error):
                throw error // Cleanup failure is never accepted as cancellation.
            case .success:
                throw CapturePipelineAssertionError(message: "Pending startup ignored cancellation")
            }
            #expect(await capture.ownedSessionIDs.isEmpty)
            #expect(await capture.isCapturing(sessionID: pendingID) == false)

            let current = try await service.validatedWindow(handle)
            let recoveredID = try await capture.startCapture(request: CaptureRequest(window: current, excludedBundleIDs: []))
            _ = try await service.validatedWindow(handle)
            let stream = try await capture.frames(sessionID: recoveredID)
            let frame = try await firstCompleteCaptureFrame(from: stream)
            #expect(frame.sessionID == recoveredID && recoveredID != pendingID)
            try await capture.stopCaptureReportingErrors(sessionID: recoveredID)
            #expect(await capture.ownedSessionIDs.isEmpty)
        } catch {
            startup.cancel()
            _ = await startup.result
            try await capture.stopAllCaptures()
            throw error
        }
    }

    @Test("Stop during an observed pending startup terminates Start and allows immediate reuse",
          .enabled(if: runCaptureIntegration))
    func liveStopDuringStartupAndReuse() async throws {
        try #require(CGPreflightScreenCaptureAccess() && AXIsProcessTrusted(), "Pre-granted Recording/AX required")
        let service = NativeWindowService()
        let fixture = try await requireFixtureDescriptor(using: service, title: Self.fixtureTitles[0])
        let handle = try #require(fixture.runtimeHandle)
        let request = try CaptureRequest(window: try await service.validatedWindow(handle), excludedBundleIDs: [])
        let capture = ScreenCaptureCoordinator()
        let startup = Task { try await capture.startCapture(request: request) }
        do {
            let pendingID = try await requirePendingCaptureID(in: capture)
            let stoppedAt = ContinuousClock.now
            try await capture.stopAllCaptures()
            switch await startup.result {
            case .failure(let error) where error is CancellationError:
                break
            case .failure(let error):
                throw error // Timeout or failed teardown cannot masquerade as Stop cancellation.
            case .success:
                throw CapturePipelineAssertionError(message: "Stopped startup returned a session")
            }
            #expect(ContinuousClock.now - stoppedAt < .seconds(4))
            #expect(await capture.ownedSessionIDs.isEmpty)
            let current = try await service.validatedWindow(handle)
            let recoveredID = try await capture.startCapture(request: CaptureRequest(window: current, excludedBundleIDs: []))
            _ = try await service.validatedWindow(handle)
            let stream = try await capture.frames(sessionID: recoveredID)
            let frame = try await firstCompleteCaptureFrame(from: stream)
            #expect(frame.sessionID == recoveredID && recoveredID != pendingID)
            try await capture.stopCaptureReportingErrors(sessionID: recoveredID)
            #expect(await capture.ownedSessionIDs.isEmpty)
        } catch {
            startup.cancel()
            _ = await startup.result
            try await capture.stopAllCaptures()
            throw error
        }
    }

    @Test("Concurrent Start and cancelled/normal Stop callers preserve single ownership across three real cycles",
          .enabled(if: runCaptureIntegration))
    func liveConcurrentCaptureOwnershipCycles() async throws {
        try #require(CGPreflightScreenCaptureAccess() && AXIsProcessTrusted(), "Pre-granted Recording/AX required")
        let service = NativeWindowService()
        let fixture = try await requireFixtureDescriptor(using: service, title: Self.fixtureTitles[0])
        let handle = try #require(fixture.runtimeHandle)
        let capture = ScreenCaptureCoordinator()
        var completedIDs: Set<CaptureSessionID> = []
        do {
            for cycle in 1...3 {
                let current = try await service.validatedWindow(handle)
                let request = try CaptureRequest(window: current, excludedBundleIDs: [])
                let first = Task { try await capture.startCapture(request: request) }
                let second = Task { try await capture.startCapture(request: request) }
                let outcomes = await (first.result, second.result)
                let results = [outcomes.0, outcomes.1]
                let startedIDs = results.compactMap { try? $0.get() }
                try #require(startedIDs.count == 1, "Concurrent starts must produce exactly one session")
                for result in results {
                    if case .failure(let error) = result {
                        guard let error = error as? AetherError, case .invalidState = error else { throw error }
                    }
                }
                let id = startedIDs[0]
                #expect(completedIDs.insert(id).inserted)
                #expect(await capture.ownedSessionIDs == [id])
                #expect(await capture.isCapturing(sessionID: id))
                _ = try await service.validatedWindow(handle)
                let stream = try await capture.frames(sessionID: id)
                let frame = try await firstCompleteCaptureFrame(from: stream)
                #expect(frame.sessionID == id && frame.metadata.isComplete)
                #expect(frame.metadata.width == frame.pixels.width && frame.metadata.height == frame.pixels.height)

                let cancelledStop = Task {
                    withUnsafeCurrentTask { $0?.cancel() }
                    try await capture.stopCaptureReportingErrors(sessionID: id)
                }
                let normalStop = Task { try await capture.stopCaptureReportingErrors(sessionID: id) }
                let stops = await (cancelledStop.result, normalStop.result)
                try stops.0.get()
                try stops.1.get()
                #expect(await capture.ownedSessionIDs.isEmpty)
                #expect(await capture.isCapturing(sessionID: id) == false)
                // At most one newest-only buffered pre-stop frame may remain; delivery then ends.
                let bufferedFrames = try await withThrowingTaskGroup(of: Int.self) { group in
                    group.addTask {
                        var count = 0
                        for try await _ in stream {
                            count += 1
                            guard count <= 1 else {
                                throw CapturePipelineAssertionError(message: "Stream delivered new frames after confirmed Stop")
                            }
                        }
                        return count
                    }
                    group.addTask {
                        try await Task.sleep(for: .seconds(1))
                        throw AetherError.timeout("Stopped stream did not finish within one second")
                    }
                    defer { group.cancelAll() }
                    return try #require(try await group.next())
                }
                #expect(bufferedFrames <= 1)
                try await capture.stopCaptureReportingErrors(sessionID: id)
                try await capture.stopAllCaptures()
                #expect(await capture.ownedSessionIDs.isEmpty)
                print("M2 concurrency cycle \(cycle): real frame, one owner, both Stop callers completed")
            }
            #expect(completedIDs.count == 3)
        } catch {
            try await capture.stopAllCaptures()
            throw error
        }
    }

    @Test("One-shot snapshot releases all ownership and default preview presents one static frame",
          .enabled(if: runCaptureIntegration))
    func liveSnapshotAndDefaultPreview() async throws {
        try #require(CGPreflightScreenCaptureAccess() && AXIsProcessTrusted(), "Pre-granted Recording/AX required")
        let service = NativeWindowService()
        let fixture = try await requireFixtureDescriptor(using: service, title: Self.fixtureTitles[0])
        let handle = try #require(fixture.runtimeHandle)
        let original = try #require(fixture.frame?.cgRect)
        let frontmostBefore = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let capture = ScreenCaptureCoordinator()
        let request = try CaptureRequest(window: try await service.validatedWindow(handle), excludedBundleIDs: [])
        let frame = try await capture.captureSnapshot(request: request)
        _ = try await service.validatedWindow(handle)
        #expect(frame.metadata.isComplete)
        #expect(frame.pixels.width > 0 && frame.pixels.width <= BGRAPixelFrame.maximumDimension)
        #expect(frame.pixels.height > 0 && frame.pixels.height <= BGRAPixelFrame.maximumDimension)
        #expect(frame.pixels.bytes.count == frame.pixels.bytesPerRow * frame.pixels.height)
        #expect(frame.pixels.bytes.contains { $0 != 0 })
        #expect(ProcessInfo.processInfo.systemUptime - frame.receivedAtUptime <= 1)
        #expect(await capture.ownedSessionIDs.isEmpty)
        #expect(await capture.isCapturing(sessionID: frame.sessionID) == false)
        let secondRequest = try CaptureRequest(window: try await service.validatedWindow(handle), excludedBundleIDs: [])
        let second = try await capture.captureSnapshot(request: secondRequest)
        #expect(second.sessionID != frame.sessionID && second.metadata.isComplete)
        #expect(await capture.ownedSessionIDs.isEmpty)
        try await capture.stopAllCaptures()

        let preview = WindowPreviewCoordinator(windows: service)
        let report = try await preview.preview(handle, configuration: .default, duration: .seconds(1))
        #expect(report.mode == .snapshot && report.framesPresented == 1)
        #expect(report.overlayRemoved && report.nativeFrameUnchanged)
        #expect(!preview.isOverlayVisible)
        #expect(WindowGeometry.approximatelyEqual(try #require(cgWindowFrame(windowID: fixture.id)), original))
        #expect(NSWorkspace.shared.frontmostApplication?.processIdentifier == frontmostBefore)
    }

    @Test("Snapshot cancellation and Stop retain pending callbacks until cleanup, then allow reuse",
          .enabled(if: runCaptureIntegration), arguments: [false, true])
    func liveSnapshotCancellationAndReuse(stopInsteadOfCancel: Bool) async throws {
        try #require(CGPreflightScreenCaptureAccess() && AXIsProcessTrusted(), "Pre-granted Recording/AX required")
        let service = NativeWindowService()
        let fixture = try await requireFixtureDescriptor(using: service, title: Self.fixtureTitles[0])
        let handle = try #require(fixture.runtimeHandle)
        let request = try CaptureRequest(window: try await service.validatedWindow(handle), excludedBundleIDs: [])
        let capture = ScreenCaptureCoordinator()
        let snapshot = Task { try await capture.captureSnapshot(request: request) }
        do {
            let pendingID = try await requirePendingCaptureID(in: capture)
            if stopInsteadOfCancel { try await capture.stopAllCaptures() } else { snapshot.cancel() }
            switch await snapshot.result {
            case .failure(let error) where error is CancellationError: break
            case .failure(let error): throw error
            case .success: throw CapturePipelineAssertionError(message: "Cancelled snapshot delivered a frame")
            }
            #expect(await capture.ownedSessionIDs.isEmpty)
            let current = try await service.validatedWindow(handle)
            let recovered = try await capture.captureSnapshot(request: CaptureRequest(window: current, excludedBundleIDs: []))
            _ = try await service.validatedWindow(handle)
            #expect(recovered.sessionID != pendingID && recovered.metadata.isComplete)
            #expect(ProcessInfo.processInfo.systemUptime - recovered.receivedAtUptime <= 1)
            #expect(await capture.ownedSessionIDs.isEmpty)
        } catch {
            snapshot.cancel()
            _ = await snapshot.result
            try await capture.stopAllCaptures()
            throw error
        }
    }

    @Test("Snapshot exclusions and pre-cancellation never acquire ownership",
          .enabled(if: runCaptureIntegration))
    func liveSnapshotPrivacyBoundaries() async throws {
        let service = NativeWindowService()
        let fixture = try await requireFixtureDescriptor(using: service, title: Self.fixtureTitles[0])
        let capture = ScreenCaptureCoordinator()
        try await expectAetherError(.permissionDenied) {
            _ = try await capture.captureSnapshot(request: CaptureRequest(window: fixture, excludedBundleIDs: [Self.fixtureBundleIdentifier]))
        }
        #expect(await capture.ownedSessionIDs.isEmpty)
        let request = try CaptureRequest(window: fixture, excludedBundleIDs: [])
        let cancelled = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await capture.captureSnapshot(request: request)
        }
        await #expect(throws: CancellationError.self) { _ = try await cancelled.value }
        #expect(await capture.ownedSessionIDs.isEmpty)
    }

    @Test("Default snapshot preview cancellation removes its static overlay and remains reusable",
          .enabled(if: runCaptureIntegration))
    func liveSnapshotPreviewCancellation() async throws {
        let service = NativeWindowService()
        let fixture = try await requireFixtureDescriptor(using: service, title: Self.fixtureTitles[0])
        let handle = try #require(fixture.runtimeHandle)
        let original = try #require(fixture.frame?.cgRect)
        let preview = WindowPreviewCoordinator(windows: service)
        let task = Task { try await preview.preview(handle, configuration: .default) }
        do {
            let deadline = ContinuousClock.now.advanced(by: .seconds(8))
            while preview.framesPresented == 0 && ContinuousClock.now < deadline {
                try await Task.sleep(for: .milliseconds(10))
            }
            try #require(preview.framesPresented == 1 && preview.isOverlayVisible)
            preview.removeOverlay()
            #expect(!preview.isOverlayVisible)
            task.cancel()
            switch await task.result {
            case .failure(let error) where error is CancellationError: break
            case .failure(let error): throw error
            case .success: throw CapturePipelineAssertionError(message: "Cancelled snapshot preview succeeded")
            }
            #expect(WindowGeometry.approximatelyEqual(try #require(cgWindowFrame(windowID: fixture.id)), original))
            // Cancellation during AX validation can intentionally invalidate its generation.
            // Refresh the SAME controlled native window, rather than weakening stale-handle checks.
            let recovered = try await requireFixtureDescriptor(using: service, title: Self.fixtureTitles[0])
            try #require(recovered.id == fixture.id && recovered.processID == fixture.processID)
            let report = try await preview.preview(try #require(recovered.runtimeHandle), configuration: .default, duration: .seconds(1))
            #expect(report.mode == .snapshot && report.framesPresented == 1 && report.overlayRemoved)
        } catch {
            task.cancel()
            _ = await task.result
            preview.removeOverlay()
            throw error
        }
    }

    @Test("Snapshot and stream admission share exactly one capture owner",
          .enabled(if: runCaptureIntegration))
    func liveSnapshotStreamAdmission() async throws {
        let service = NativeWindowService()
        let fixture = try await requireFixtureDescriptor(using: service, title: Self.fixtureTitles[0])
        let handle = try #require(fixture.runtimeHandle)
        let request = try CaptureRequest(window: try await service.validatedWindow(handle), excludedBundleIDs: [])
        let capture = ScreenCaptureCoordinator()
        let streamID = try await capture.startCapture(request: request)
        do {
            try await expectAetherError(.invalidState) { _ = try await capture.captureSnapshot(request: request) }
            #expect(await capture.ownedSessionIDs == [streamID])
            try await capture.stopAllCaptures()
        } catch { try await capture.stopAllCaptures(); throw error }
        let snapshot = Task { try await capture.captureSnapshot(request: request) }
        do {
            let id = try await requirePendingCaptureID(in: capture)
            try await expectAetherError(.invalidState) { _ = try await capture.startCapture(request: request) }
            try await expectAetherError(.invalidState) { _ = try await capture.captureSnapshot(request: request) }
            let frame = try await snapshot.value
            #expect(frame.sessionID == id && frame.metadata.isComplete)
            #expect(await capture.ownedSessionIDs.isEmpty)
            _ = try await service.validatedWindow(handle)
        } catch {
            snapshot.cancel()
            _ = await snapshot.result
            try await capture.stopAllCaptures()
            throw error
        }
    }

    /// Await an observed inactive lease; fail instead of claiming a pre-cancel or active-stop proof.
    private func requirePendingCaptureID(in capture: ScreenCaptureCoordinator) async throws -> CaptureSessionID {
        let deadline = ContinuousClock.now.advanced(by: .seconds(2))
        var owned = await capture.ownedSessionIDs
        while owned.isEmpty && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(1))
            owned = await capture.ownedSessionIDs
        }
        try #require(owned.count == 1, "No startup lease observed within two seconds")
        let id = try #require(owned.first)
        try #require(await capture.isCapturing(sessionID: id) == false,
                     "Startup completed before a pending lease could be observed; boundary not exercised")
        return id
    }

    /// Two-second real-frame deadline. The losing structured task is cancelled and awaited.
    private func firstCompleteCaptureFrame(from stream: AsyncThrowingStream<CapturedFrame, any Error>) async throws -> CapturedFrame {
        try await withThrowingTaskGroup(of: CapturedFrame.self) { group in
            group.addTask {
                for try await frame in stream {
                    guard frame.metadata.isComplete,
                          ProcessInfo.processInfo.systemUptime - frame.receivedAtUptime <= 1 else {
                        throw CapturePipelineAssertionError(message: "Received an incomplete or stale live frame")
                    }
                    return frame
                }
                throw CapturePipelineAssertionError(message: "Capture ended without a complete frame")
            }
            group.addTask {
                try await Task.sleep(for: .seconds(2))
                throw AetherError.timeout("No complete live frame arrived within two seconds")
            }
            defer { group.cancelAll() }
            return try #require(try await group.next())
        }
    }

    /// Strictly local AX ownership: only a uniquely matched, correlated external Test Lab window.
    private func fixtureAXWindow(_ fixture: WindowDescriptor) throws -> AXUIElement {
        try #require(fixture.bundleIdentifier == Self.fixtureBundleIdentifier && fixture.runtimeHandle != nil)
        let app = try #require(NSRunningApplication(processIdentifier: fixture.processID))
        try #require(app.bundleIdentifier == Self.fixtureBundleIdentifier && !app.isTerminated)
        let root = AXUIElementCreateApplication(fixture.processID)
        try #require(AXUIElementSetMessagingTimeout(root, 0.15) == .success)
        let elements = try #require(try fixtureAXAttribute(root, kAXWindowsAttribute) as? [AXUIElement])
        try #require(elements.count <= 128)
        let expected = try #require(fixture.frame?.cgRect)
        var matches: [AXUIElement] = []
        for element in elements {
            try #require(AXUIElementSetMessagingTimeout(element, 0.15) == .success)
            guard try fixtureAXAttribute(element, kAXRoleAttribute) as? String == kAXWindowRole,
                  try fixtureAXAttribute(element, kAXTitleAttribute) as? String == fixture.title,
                  let position = try fixtureAXAttribute(element, kAXPositionAttribute),
                  let size = try fixtureAXAttribute(element, kAXSizeAttribute),
                  CFGetTypeID(position) == AXValueGetTypeID(), CFGetTypeID(size) == AXValueGetTypeID() else { continue }
            let positionValue = unsafeDowncast(position, to: AXValue.self)
            let sizeValue = unsafeDowncast(size, to: AXValue.self)
            guard AXValueGetType(positionValue) == .cgPoint, AXValueGetType(sizeValue) == .cgSize else { continue }
            var point = CGPoint.zero
            var dimensions = CGSize.zero
            guard AXValueGetValue(positionValue, .cgPoint, &point), AXValueGetValue(sizeValue, .cgSize, &dimensions),
                  WindowGeometry.approximatelyEqual(CGRect(origin: point, size: dimensions), expected) else { continue }
            matches.append(element)
        }
        try #require(matches.count == 1, "Fixture AX identity is absent or ambiguous")
        return matches[0]
    }

    private func fixtureAXAttribute(_ element: AXUIElement, _ attribute: String) throws -> CFTypeRef? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        try #require(result == .success, "Fixture AX read \(attribute) failed: \(result.rawValue)")
        return value
    }

    private func setFixtureMinimized(_ minimized: Bool, element: AXUIElement) throws {
        var settable = DarwinBoolean(false)
        try #require(AXUIElementIsAttributeSettable(element, kAXMinimizedAttribute as CFString, &settable) == .success)
        try #require(settable.boolValue)
        try #require(AXUIElementSetAttributeValue(element, kAXMinimizedAttribute as CFString,
                                                 minimized ? kCFBooleanTrue : kCFBooleanFalse) == .success)
    }

    private func makeLiveCaptureRequest(using service: NativeWindowService) async throws -> CaptureRequest? {
        let descriptors = try await service.refresh()
        guard let descriptor = descriptors.first(where: { candidate in
            candidate.runtimeHandle != nil
            && candidate.frame != nil
            && !(candidate.bundleIdentifier ?? "").isEmpty
            && candidate.isOnScreen
            && !candidate.isMinimized
        }) else {
            return nil
        }
        return try CaptureRequest(window: descriptor, excludedBundleIDs: [])
    }

    private func requireFixtureDescriptor(using service: NativeWindowService, title: String? = nil) async throws -> WindowDescriptor {
        try #require(!IsSecureEventInputEnabled(), "Unlock the desktop and finish secure input before live capture tests")
        _ = try #require(
            NSRunningApplication.runningApplications(withBundleIdentifier: Self.fixtureBundleIdentifier)
                .first(where: { !$0.isTerminated }),
            "Launch external Test Lab fixtures (bundle \(Self.fixtureBundleIdentifier))"
        )

        let deadline = ContinuousClock.now.advanced(by: .seconds(10))
        while true {
            let fixtures = try await service.refresh().filter { $0.bundleIdentifier == Self.fixtureBundleIdentifier }
            if let fixture = fixtures.first(where: { descriptor in
                (title.map { $0 == descriptor.title } ?? Self.fixtureTitles.contains(descriptor.title ?? ""))
                && descriptor.runtimeHandle != nil
                && descriptor.frame != nil
                && descriptor.isOnScreen
                && !descriptor.isMinimized
            }) { return fixture }
            guard ContinuousClock.now < deadline else {
                throw CapturePipelineAssertionError(message: "No capture-eligible Test Lab fixture was discovered within ten seconds")
            }
            try await Task.sleep(for: .milliseconds(80))
        }
    }

    private func cgWindowFrame(windowID: WindowID) -> CGRect? {
        guard let rows = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        for row in rows {
            guard let number = row[kCGWindowNumber as String] as? NSNumber,
                  number.uint32Value == windowID.rawValue,
                  let bounds = row[kCGWindowBounds as String] as? NSDictionary,
                  let frame = CGRect(dictionaryRepresentation: bounds),
                  frame.width > 0,
                  frame.height > 0 else {
                continue
            }
            return frame
        }
        return nil
    }

    private func expectAetherError(_ expected: ExpectedAetherError,
                                   _ operation: () async throws -> Void) async throws {
        do {
            try await operation()
            throw CapturePipelineAssertionError(message: "Expected AetherError.\(expected.rawValue), but operation succeeded")
        } catch let error as AetherError {
            guard expected.matches(error) else {
                throw CapturePipelineAssertionError(message: "Expected AetherError.\(expected.rawValue), got \(error)")
            }
        }
    }

    private func expectAetherError(_ expected: ExpectedAetherError,
                                   _ operation: () throws -> Void) throws {
        do {
            try operation()
            throw CapturePipelineAssertionError(message: "Expected AetherError.\(expected.rawValue), but operation succeeded")
        } catch let error as AetherError {
            guard expected.matches(error) else {
                throw CapturePipelineAssertionError(message: "Expected AetherError.\(expected.rawValue), got \(error)")
            }
        }
    }
}

private enum ExpectedAetherError: String {
    case unsupported
    case permissionDenied
    case invalidState

    func matches(_ error: AetherError) -> Bool {
        switch (self, error) {
        case (.unsupported, .unsupported),
               (.permissionDenied, .permissionDenied),
               (.invalidState, .invalidState):
            return true
        default:
            return false
        }
    }
}

enum CaptureInterruption: String, CaseIterable, Sendable {
    case move, minimize, close
}

private struct CapturePipelineAssertionError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
