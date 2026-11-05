import AppKit
import XCTest
@testable import AETHERCore
@testable import AETHERInterface
import AETHERShared

/// Ordinary tests are passive: no engine launch, permission prompts or native-window mutations.
final class KinetiqEngineTests: XCTestCase {
    func testRealTerminalBundleIsRejected() throws {
        let terminal = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app", isDirectory: true)
        guard FileManager.default.fileExists(atPath: terminal.path) else {
            throw XCTSkip("The real system Terminal.app is unavailable on this host.")
        }
        XCTAssertThrowsError(try KinetiqEngineCoordinator.validateApplication(at: terminal)) { error in
            guard case KinetiqEngineError.invalidApplication = error else {
                return XCTFail("Expected a real non-Kinetiq bundle to be rejected, got \(error)")
            }
        }
    }

    func testRealKinetiqBundleMetadataAndCanonicalPath() throws {
        let url = try realApplicationURL()
        let info = try KinetiqEngineCoordinator.validateApplication(at: url)
        XCTAssertEqual(info.applicationURL, url.standardizedFileURL.resolvingSymlinksInPath())
        XCTAssertEqual(info.executableURL.lastPathComponent, "Kinetiq")
        XCTAssertFalse(info.version.isEmpty)
        XCTAssertFalse(info.build.isEmpty)
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: info.executableURL.path))
        let redundant = url.appendingPathComponent("Contents/..", isDirectory: true)
        XCTAssertEqual(try KinetiqEngineCoordinator.validateApplication(at: redundant), info)
    }

    @MainActor
    func testConstructionIsPassiveAndConsentIsRequired() async throws {
        let before = runningIdentities()
        let engine = KinetiqEngineCoordinator()
        XCTAssertFalse(engine.isStarting)
        XCTAssertFalse(engine.isLaunchPending)
        XCTAssertFalse(engine.isRunning)
        XCTAssertNil(engine.processID)
        XCTAssertNil(engine.metadata)
        do {
            try await engine.start(applicationURL: URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"),
                                   experimentalConsent: false)
            XCTFail("Launch must require explicit consent even before bundle validation")
        } catch {
            XCTAssertEqual(error as? KinetiqEngineError, .consentRequired)
        }
        XCTAssertEqual(runningIdentities(), before)
        XCTAssertFalse(engine.isLaunchPending)
    }

    @MainActor
    func testCancelledStartDoesNotIssueLaunchRequest() async throws {
        let before = runningIdentities()
        let engine = KinetiqEngineCoordinator()
        let task = Task { @MainActor in
            withUnsafeCurrentTask { $0?.cancel() }
            try await engine.start(applicationURL: URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"),
                                   experimentalConsent: true)
        }
        do {
            try await task.value
            XCTFail("A pre-cancelled task must fail before launching")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        XCTAssertFalse(engine.isStarting)
        XCTAssertFalse(engine.isLaunchPending)
        XCTAssertNil(engine.processID)
        XCTAssertEqual(runningIdentities(), before)
    }

    @MainActor
    func testInvalidBundleCannotCreatePendingLaunch() async throws {
        let engine = KinetiqEngineCoordinator()
        do {
            try await engine.start(applicationURL: URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"),
                                   experimentalConsent: true)
            XCTFail("An unrelated application must never be launched")
        } catch {
            guard case KinetiqEngineError.invalidApplication = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertFalse(engine.isLaunchPending)
        XCTAssertFalse(engine.isStarting)
        XCTAssertNil(engine.processID)
        XCTAssertNotNil(engine.lastError)
    }

    @MainActor
    func testCancelledStopHasNoSideEffects() async throws {
        let before = runningIdentities()
        let engine = KinetiqEngineCoordinator()
        let task = Task { @MainActor in
            withUnsafeCurrentTask { $0?.cancel() }
            try await engine.stop()
        }
        do {
            try await task.value
            XCTFail("A pre-cancelled stop must not issue a quit request")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        XCTAssertFalse(engine.isStopping)
        XCTAssertEqual(runningIdentities(), before)
    }

    @MainActor
    func testLiveLaunchConnectAndGracefulStopOnlyWithExplicitOptIn() async throws {
        guard ProcessInfo.processInfo.environment["AETHER_RUN_KINETIQ_INTEGRATION"] == "1" else {
            throw XCTSkip("Set AETHER_RUN_KINETIQ_INTEGRATION=1 to explicitly allow the real global engine and its own permission prompts. No window interactions are automated.")
        }
        guard runningIdentities().isEmpty else {
            throw XCTSkip("Quit existing Kinetiq instances manually first; this test never stops a user's pre-existing engine.")
        }
        let url = try realApplicationURL()
        let expected = try KinetiqEngineCoordinator.validateApplication(at: url)
        let engine = KinetiqEngineCoordinator()
        // XCTest awaits this cleanup even if a throwing assertion or launch wait aborts the test.
        // Failure remains visible; cleanup never escalates to a force quit.
        addTeardownBlock { @MainActor in
            do {
                try await engine.stop()
            } catch {
                XCTFail("Normal Kinetiq cleanup failed: \(error). Use its wave menu to quit; no forced kill was attempted.")
            }
        }
        try await engine.start(applicationURL: url, experimentalConsent: true)
        let pid = try XCTUnwrap(engine.processID)
        let app = try XCTUnwrap(NSRunningApplication(processIdentifier: pid))
        let running = engine.isRunning
        let active = engine.isActive
        let metadata = engine.metadata
        let reportedIdentifier = app.bundleIdentifier
        let reportedBundle = app.bundleURL?.standardizedFileURL.resolvingSymlinksInPath()
        let reportedExecutable = app.executableURL?.standardizedFileURL.resolvingSymlinksInPath()
        try await engine.start(applicationURL: url, experimentalConsent: true)
        let connectedPID = engine.processID
        let connection = KinetiqEngineCoordinator()
        connection.refreshStatus()
        let detectedWithoutControl = connection.isActive && !connection.isRunning && connection.processID == nil
        try await connection.start(applicationURL: url, experimentalConsent: true)
        let independentlyConnectedPID = connection.processID
        let unconsented = KinetiqEngineCoordinator()
        do {
            try await unconsented.start(applicationURL: url, experimentalConsent: false)
            XCTFail("Connecting to an existing real process must also require consent")
        } catch {
            XCTAssertEqual(error as? KinetiqEngineError, .consentRequired)
        }
        XCTAssertNil(unconsented.processID)

        // Exercise the real UI command boundary, not just disabled buttons or the manager flag.
        // Only an empty controlled disposable is admissible, even if an interlock regression
        // accidentally executes a command. No unrelated application/document is ever selected.
        let runtime = AetherRuntimeModel()
        await runtime.start()
        XCTAssertTrue(runtime.isRunning, "AETHER must have real loaded configuration for this test")
        let deadline = ContinuousClock.now.advanced(by: .seconds(10))
        var fixture: WindowDescriptor?
        repeat {
            await runtime.performWindowCommand(.refresh)
            fixture = runtime.windows.first {
                $0.bundleIdentifier == "com.aether.testlab" && $0.title == "AETHER Effect Disposable"
                    && $0.runtimeHandle != nil && $0.isOnScreen && !$0.isMinimized
            }
            if fixture != nil { break }
            try await Task.sleep(for: .milliseconds(80))
        } while ContinuousClock.now < deadline
        let controlled = try XCTUnwrap(fixture, "Launch exactly one real Test Lab --m1-fixtures before opting in")
        let handle = try XCTUnwrap(controlled.runtimeHandle)
        let frame = try XCTUnwrap(controlled.frame)
        let commands: [WindowPanelCommand] = [
            .focus(handle), .setFrame(handle, frame), .preview(handle), .livePreview(handle),
            .effect(handle, .wobble), .effect(handle, .dissolveClose)
        ]
        for command in commands {
            await runtime.performWindowCommand(command)
            XCTAssertTrue(runtime.windowMessage?.contains("Stop Kinetiq") == true,
                          "Every non-discovery command must reject the active external engine")
            XCTAssertFalse(runtime.isWindowOperationRunning)
            XCTAssertFalse(runtime.isPreviewRunning)
        }
        await runtime.performWindowCommand(.refresh)
        let unchanged = try XCTUnwrap(runtime.windows.first { $0.id == controlled.id && $0.processID == controlled.processID })
        XCTAssertEqual(unchanged.frame, controlled.frame)
        XCTAssertTrue(unchanged.isOnScreen && !unchanged.isMinimized)
        // Stop before assertions so assertion failures do not leave a global engine running.
        try await engine.stop()
        connection.refreshStatus()
        XCTAssertTrue(running)
        XCTAssertTrue(active)
        XCTAssertEqual(metadata, expected)
        XCTAssertEqual(reportedIdentifier, KinetiqEngineCoordinator.bundleIdentifier)
        XCTAssertEqual(reportedBundle, expected.applicationURL)
        XCTAssertEqual(reportedExecutable, expected.executableURL)
        XCTAssertEqual(connectedPID, pid)
        XCTAssertTrue(detectedWithoutControl)
        XCTAssertEqual(independentlyConnectedPID, pid)
        XCTAssertFalse(connection.isRunning)
        XCTAssertTrue(app.isTerminated)
        XCTAssertFalse(engine.isRunning)
        XCTAssertFalse(engine.isLaunchPending)
        XCTAssertFalse(engine.isActive)
        XCTAssertNil(engine.processID)
    }

    private func realApplicationURL() throws -> URL {
        guard let url = KinetiqEngineCoordinator.applicationCandidates.first(where: {
            FileManager.default.fileExists(atPath: $0.path)
        }) else {
            throw XCTSkip("No real Kinetiq.app found. Build sibling Wobbly/build/Kinetiq.app or install in ~/Applications or /Applications.")
        }
        return url
    }

    @MainActor
    private func runningIdentities() -> Set<Int32> {
        Set(NSRunningApplication.runningApplications(withBundleIdentifier: KinetiqEngineCoordinator.bundleIdentifier)
            .filter { !$0.isTerminated }.map(\.processIdentifier))
    }
}