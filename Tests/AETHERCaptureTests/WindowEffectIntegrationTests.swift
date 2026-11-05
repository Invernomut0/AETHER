import AppKit
import ApplicationServices
import Carbon
import CoreGraphics
import Foundation
import Testing
import AETHERShared
import AETHERCore
import AETHERWindowManager

private let runEffects = ProcessInfo.processInfo.environment["AETHER_RUN_EFFECT_INTEGRATION"] == "1"

/// Separate opt-in suite: never run native/capture mutation suites concurrently on these windows.
@MainActor
@Suite("Explicit one-shot window effects", .serialized, .enabled(if: runEffects))
struct WindowEffectIntegrationTests {
    @Test("Real captured wobble completes and leaves native frame/focus unchanged")
    func wobbleAndReuse() async throws {
        let windows = NativeWindowService()
        let fixture = try await target(windows)
        let handle = try #require(fixture.runtimeHandle)
        let original = try #require(fixture.frame?.cgRect)
        let focus = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let effects = WindowEffectCoordinator(windows: windows)
        for forceReduceMotion in [false, true] {
            var configuration = AetherConfiguration.default
            configuration.reduceMotion = forceReduceMotion
            let report = try await effects.perform(.wobble, on: handle, configuration: configuration,
                                                   duration: .milliseconds(800))
            #expect(report.kind == .wobble && report.framesPresented > 1)
            #expect(report.reducedMotion == (forceReduceMotion || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion))
            #expect(report.overlayRemoved && !report.nativeWindowClosed && !effects.isOverlayVisible)
            let after = try await windows.validatedWindow(handle)
            #expect(WindowGeometry.approximatelyEqual(try #require(after.frame?.cgRect), original))
        }
        #expect(NSWorkspace.shared.frontmostApplication?.processIdentifier == focus)
    }

    @Test("Stop/cancellation after real GPU presentation removes wobble and allows reuse")
    func cancellationAndReuse() async throws {
        let windows = NativeWindowService()
        let fixture = try await target(windows)
        let effects = WindowEffectCoordinator(windows: windows)
        let task = Task { try await effects.perform(.wobble, on: try #require(fixture.runtimeHandle), configuration: .default) }
        do {
            try await awaitFrame(effects)
            effects.removeOverlay()
            #expect(!effects.isOverlayVisible)
            task.cancel()
            switch await task.result {
            case .success: Issue.record("Cancelled wobble unexpectedly succeeded")
            case .failure(let error) where error is CancellationError: break
            case .failure(let error):
                guard let aether = error as? AetherError, aether == .cancelled else { throw error }
            }
            let recovered = try await target(windows)
            try #require(recovered.id == fixture.id && recovered.processID == fixture.processID)
            let report = try await effects.perform(.wobble, on: try #require(recovered.runtimeHandle), configuration: .default,
                                                   duration: .milliseconds(300))
            #expect(report.framesPresented > 1 && report.overlayRemoved)
        } catch {
            task.cancel()
            _ = await task.result
            effects.removeOverlay()
            throw error
        }
    }

    @Test("Native movement interrupts wobble without rollback")
    func nativeMovementInterrupts() async throws {
        let windows = NativeWindowService()
        let fixture = try await target(windows)
        let original = try #require(fixture.frame?.cgRect)
        let handle = try #require(fixture.runtimeHandle)
        let moved = original.offsetBy(dx: 24, dy: 16)
        let effects = WindowEffectCoordinator(windows: windows)
        let task = Task { try await effects.perform(.wobble, on: handle, configuration: .default) }
        var savedError: (any Error)?
        do {
            try await awaitFrame(effects)
            try await windows.setFrame(moved, for: handle)
            switch await task.result {
            case .success: Issue.record("Native mutation did not interrupt wobble")
            case .failure(let error):
                guard let aether = error as? AetherError else { throw error }
                switch aether {
                case .invalidState, .notFound: break
                default: throw error // Never accept timeout/failed cleanup as interruption proof.
                }
            }
            #expect(!effects.isOverlayVisible)
            let current = try await target(windows)
            #expect(WindowGeometry.approximatelyEqual(try #require(current.frame?.cgRect), moved))
        } catch { savedError = error }
        task.cancel()
        _ = await task.result
        effects.removeOverlay()
        // Test restores only its controlled fixture; the effect itself never rolls back user motion.
        let current = try await target(windows)
        try #require(current.id == fixture.id && current.processID == fixture.processID)
        try await windows.setFrame(original, for: try #require(current.runtimeHandle))
        if let savedError { throw savedError }
    }

    @Test("Privacy exclusion and pre-cancellation never send native close", arguments: [WindowEffectKind.wobble, .dissolveClose])
    func privacyAndPreCancellation(_ kind: WindowEffectKind) async throws {
        let windows = NativeWindowService()
        let fixture = try await target(windows)
        let handle = try #require(fixture.runtimeHandle)
        let effects = WindowEffectCoordinator(windows: windows)
        var excluded = AetherConfiguration.default
        excluded.captureExcludedBundleIDs.append("com.aether.testlab")
        do {
            _ = try await effects.perform(kind, on: handle, configuration: excluded)
            Issue.record("Excluded fixture was captured")
        } catch let error as AetherError {
            guard case .permissionDenied = error else { throw error }
        }
        #expect(!effects.isOverlayVisible && effects.framesPresented == 0)
        let cancelled = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await effects.perform(kind, on: handle, configuration: .default)
        }
        await #expect(throws: CancellationError.self) { _ = try await cancelled.value }
        #expect(try inventoryContains(handle))
        #expect(!effects.isOverlayVisible && effects.framesPresented == 0)
    }

    @Test("A real app refusing close never starts the dissolve or hides its native window")
    func refusedCloseDoesNotAnimate() async throws {
        let windows = NativeWindowService()
        let fixture = try await target(windows, title: "AETHER Refuses Close")
        let handle = try #require(fixture.runtimeHandle)
        try #require(fixture.capabilities.canClose)
        let effects = WindowEffectCoordinator(windows: windows)
        do {
            _ = try await effects.perform(.dissolveClose, on: handle, configuration: .default)
            Issue.record("Refused native close unexpectedly succeeded")
        } catch let error as NativeWindowCloseError {
            guard case .outcomeUnconfirmed = error else { throw error }
        }
        #expect(effects.framesPresented == 0 && !effects.isOverlayVisible)
        #expect(try inventoryContains(handle))
        let after = try await windows.validatedWindow(handle)
        #expect(after.isOnScreen && !after.isMinimized)
        #expect(after.frame == fixture.frame)
    }

    @Test("AX closes only the disposable fixture, then real captured dissolve completes")
    func nativeCloseWithDissolve() async throws {
        let windows = NativeWindowService()
        let fixture = try await target(windows, title: "AETHER Effect Disposable")
        let handle = try #require(fixture.runtimeHandle)
        try #require(fixture.capabilities.canClose)
        #expect(try inventoryContains(handle))
        let effects = WindowEffectCoordinator(windows: windows)
        let report = try await effects.perform(.dissolveClose, on: handle, configuration: .default,
                                               duration: .milliseconds(500))
        #expect(report.kind == .dissolveClose && report.nativeWindowClosed)
        #expect(report.framesPresented > 1 && report.overlayRemoved && !effects.isOverlayVisible)
        #expect(try !inventoryContains(handle))
        #expect(try windows.isWindowClosed(handle))
        // The surviving window remains capturable through the same effect/capture/render owner.
        let surviving = try await target(windows)
        let recovered = try await effects.perform(.wobble, on: try #require(surviving.runtimeHandle), configuration: .default,
                                                  duration: .milliseconds(300))
        #expect(recovered.framesPresented > 1 && recovered.overlayRemoved && !recovered.nativeWindowClosed)
    }

    private func target(_ windows: NativeWindowService, title: String = "M1 Fixture Resizable A") async throws -> WindowDescriptor {
        try #require(AXIsProcessTrusted() && CGPreflightScreenCaptureAccess() && !IsSecureEventInputEnabled(),
                     "Grant AX/Recording explicitly and unlock the desktop before opting in")
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.aether.testlab").filter { !$0.isTerminated }
        try #require(apps.count == 1, "Launch exactly one external Test Lab --m1-fixtures")
        let pid = apps[0].processIdentifier
        let deadline = ContinuousClock.now.advanced(by: .seconds(10))
        while true {
            let matches = try await windows.refresh().filter {
                $0.processID == pid && $0.bundleIdentifier == "com.aether.testlab" && $0.title == title
                    && $0.runtimeHandle != nil && $0.isOnScreen && !$0.isMinimized
            }
            if matches.count == 1 { return matches[0] }
            guard ContinuousClock.now < deadline else { throw AetherError.notFound("Controlled effect fixture unavailable or ambiguous") }
            try await Task.sleep(for: .milliseconds(50))
        }
    }

    private func awaitFrame(_ effects: WindowEffectCoordinator) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(8))
        while effects.framesPresented == 0 && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        try #require(effects.framesPresented > 0 && effects.isOverlayVisible, "No real captured GPU frame reached the overlay")
    }

    private func inventoryContains(_ handle: RuntimeWindowHandle) throws -> Bool {
        let rows = try #require(CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]])
        return rows.contains {
            ($0[kCGWindowNumber as String] as? NSNumber)?.uint32Value == handle.windowID.rawValue
                && ($0[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value == handle.processID
        }
    }
}