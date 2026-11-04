import Foundation
import Testing
import AppKit
import CoreGraphics
import ApplicationServices
import Carbon
import AETHERShared
import AETHERCapture
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
        try await capture.stopAllCaptures()
        try await capture.stopAllCaptures()
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
        let report = try await preview.preview(handle, configuration: .default, duration: .seconds(1))

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
        let task = Task { try await preview.preview(handle, configuration: .default) }
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

    private func requireFixtureDescriptor(using service: NativeWindowService) async throws -> WindowDescriptor {
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
                Self.fixtureTitles.contains(descriptor.title ?? "")
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

    func matches(_ error: AetherError) -> Bool {
        switch (self, error) {
        case (.unsupported, .unsupported),
             (.permissionDenied, .permissionDenied):
            return true
        default:
            return false
        }
    }
}

private struct CapturePipelineAssertionError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
