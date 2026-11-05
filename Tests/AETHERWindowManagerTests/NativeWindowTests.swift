import Foundation
import Testing
import AppKit
import ApplicationServices
import Carbon
@testable import AETHERWindowManager
import AETHERShared

private let runWindowIntegration = ProcessInfo.processInfo.environment["AETHER_RUN_WINDOW_INTEGRATION"] == "1"

@MainActor
@Suite("NativeWindowService live fixtures", .serialized)
struct NativeWindowTests {
    private static let fixtureBundleIdentifier = "com.aether.testlab"
    private static let fixtureResizableA = "M1 Fixture Resizable A"
    private static let fixtureResizableB = "M1 Fixture Resizable B"
    private static let fixtureFixed = "M1 Fixture Fixed"
    private static let fixtureOverlap = "M1 Fixture Overlap"
    private static let fixtureEffectDisposable = "AETHER Effect Disposable"

    @Test("Close capability defaults false and old encoded capabilities remain readable")
    func closeCapabilityCodableCompatibility() async throws {
        let windows = try await NativeWindowService().refresh()
        let observed = try #require(windows.first, "A real desktop window is required")
        #expect(WindowCapabilities().canClose == false)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let currentData = try encoder.encode(observed.capabilities)
        #expect(try decoder.decode(WindowCapabilities.self, from: currentData) == observed.capabilities)

        // Derive an old-format record from the real discovery result, not fabricated capabilities.
        var oldRecord = try #require(try JSONSerialization.jsonObject(with: currentData) as? [String: Any])
        oldRecord.removeValue(forKey: "canClose")
        let oldData = try JSONSerialization.data(withJSONObject: oldRecord)
        var expected = observed.capabilities
        expected.canClose = false
        #expect(try decoder.decode(WindowCapabilities.self, from: oldData) == expected)

        // Wrong types still fail decoding; the compatibility default is not an authorization.
        oldRecord["canClose"] = "true"
        let invalidData = try JSONSerialization.data(withJSONObject: oldRecord)
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(WindowCapabilities.self, from: invalidData)
        }
    }

    @Test("close() confirms only the exact external Effect Disposable generation", .enabled(if: runWindowIntegration))
    func closeEffectDisposableConfirmsNativeDisappearance() async throws {
        try #require(!IsSecureEventInputEnabled(), "Unlock the desktop and finish secure input")
        try #require(AXIsProcessTrusted(), "Explicit Accessibility permission is required")
        let applications = NSRunningApplication.runningApplications(withBundleIdentifier: Self.fixtureBundleIdentifier)
            .filter { !$0.isTerminated && $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        try #require(applications.count == 1, "Run exactly one external Test Lab with --m1-fixtures")
        let app = try #require(applications.first)
        let launchDate = try #require(app.launchDate)
        let service = NativeWindowService()
        let deadline = ContinuousClock.now.advanced(by: .seconds(10))
        var matches: [WindowDescriptor] = []
        while true {
            matches = try await service.refresh().filter {
                $0.processID == app.processIdentifier && $0.bundleIdentifier == Self.fixtureBundleIdentifier
                    && $0.title == Self.fixtureEffectDisposable && $0.runtimeHandle != nil
            }
            if matches.count == 1 || ContinuousClock.now >= deadline { break }
            try await Task.sleep(for: .milliseconds(80))
        }
        try #require(matches.count == 1, "Missing/ambiguous Effect Disposable; relaunch Test Lab before repeating")
        let selected = try #require(matches.first)
        let handle = try #require(selected.runtimeHandle)
        #expect(selected.capabilities.canClose)
        let validated = try await service.validatedWindow(handle)
        try #require(validated.title == Self.fixtureEffectDisposable && validated.runtimeHandle == handle)
        try #require(validated.capabilities.canClose)
        let before = try fullNativeInventory()
        let otherWindows = Set(before.filter { $0.pid == handle.processID && $0.id != handle.windowID.rawValue }.map(\.id))
        try #require(before.contains { $0.id == handle.windowID.rawValue && $0.pid == handle.processID })

        let forged = RuntimeWindowHandle(windowID: handle.windowID, processID: handle.processID)
        try await expectAetherError(.notFound) { try await service.close(forged) }
        try await expectAetherError(.notFound) { _ = try service.isWindowClosed(forged) }
        try await expectAetherError(.notFound) { _ = try service.isWindowClosed(handle) }
        let cancelled = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await service.close(handle)
        }
        await #expect(throws: CancellationError.self) { try await cancelled.value }
        try #require(try fullNativeInventory().contains { $0.id == handle.windowID.rawValue && $0.pid == handle.processID })
        try #require(app.launchDate == launchDate && !app.isTerminated)

        try await service.close(handle)
        #expect(try service.isWindowClosed(handle))
        let after = try fullNativeInventory()
        #expect(!after.contains { $0.id == handle.windowID.rawValue && $0.pid == handle.processID })
        #expect(otherWindows.isSubset(of: Set(after.filter { $0.pid == handle.processID }.map(\.id))))
        #expect(!app.isTerminated && app.launchDate == launchDate)
        try await expectAetherError(.notFound) { try await service.close(handle) }
        try await expectAetherError(.notFound) { _ = try await service.validatedWindow(handle) }
        try await expectAetherError(.notFound) { try await service.activate(handle) }
        _ = try await service.refresh()
        #expect(try service.isWindowClosed(handle), "Closure read-side remains available after discovery refresh")
    }

    /// Independent public CG assertion: never filter by visibility, frame, title or layer.
    private func fullNativeInventory() throws -> [(id: UInt32, pid: Int32)] {
        let rows = try #require(CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]])
        return try rows.map {
            let id = try #require($0[kCGWindowNumber as String] as? NSNumber)
            let pid = try #require($0[kCGWindowOwnerPID as String] as? NSNumber)
            return (id.uint32Value, pid.int32Value)
        }
    }

    @Test("Full closure inventory retains a real ordered-out NSWindow")
    func hiddenWindowIsNotClosed() async throws {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 80, y: 120, width: 320, height: 220),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.orderFront(nil)
        let handle = RuntimeWindowHandle(windowID: WindowID(rawValue: UInt32(window.windowNumber)),
                                         processID: ProcessInfo.processInfo.processIdentifier)
        let deadline = ContinuousClock.now.advanced(by: .seconds(2))
        while try !NativeWindowInventory.contains(handle), ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(40))
        }
        try #require(try NativeWindowInventory.contains(handle), "Real window must be registered before hiding")
        window.orderOut(nil)
        #expect(window.isVisible == false)
        #expect(try NativeWindowInventory.contains(handle), "Off-screen is not closed")
        #expect(try fullNativeInventory().contains { $0.id == handle.windowID.rawValue && $0.pid == handle.processID })
    }

    @Test("refresh() performs real desktop discovery without writes")
    func desktopDiscoveryReadOnly() async throws {
        let service = NativeWindowService()
        let descriptors = try await service.refresh()
        for descriptor in descriptors {
            if let frame = descriptor.frame?.cgRect {
                #expect(WindowGeometry.isValid(frame))
            }
        }
    }

    @Test("refresh() honors pre-cancellation")
    func refreshHonorsPreCancellation() async {
        let service = NativeWindowService()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await service.refresh()
        }
        await #expect(throws: CancellationError.self) {
            _ = try await task.value
        }
    }

    @Test("WindowGeometry helpers use a real AppKit NSWindow frame")
    func geometryHelpersWithRealWindowFrame() {
        _ = NSApplication.shared
        let window = NSWindow(
            contentRect: NSRect(x: 80, y: 120, width: 520, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        let frame = window.frame
        #expect(WindowGeometry.isValid(frame))

        let primaryHeight = CGDisplayBounds(CGMainDisplayID()).height
        let converted = WindowGeometry.fromAppKit(frame, primaryDisplayHeight: primaryHeight)
        let expected = CGRect(x: frame.minX, y: primaryHeight - frame.maxY, width: frame.width, height: frame.height)
        #expect(WindowGeometry.approximatelyEqual(converted, expected, tolerance: 0.01))

        let nearMatch = CGRect(x: converted.minX + 0.5,
                               y: converted.minY + 0.5,
                               width: converted.width - 0.4,
                               height: converted.height + 0.4)
        #expect(WindowGeometry.approximatelyEqual(converted, nearMatch, tolerance: 1))

        let invalid = CGRect(x: frame.minX, y: frame.minY, width: -1, height: frame.height)
        #expect(WindowGeometry.isValid(invalid) == false)
    }

    @Test("Fixture prerequisites are present on external TestLab", .enabled(if: runWindowIntegration))
    func fixturePrerequisitesExist() async throws {
        let service = NativeWindowService()
        _ = try await requireFixtureDescriptors(using: service)
    }

    @Test("Multiple resizable fixtures expose distinct runtime handles", .enabled(if: runWindowIntegration))
    func resizableFixturesExposeDistinctHandles() async throws {
        let service = NativeWindowService()
        let fixtures = try await requireFixtureDescriptors(using: service)
        let resizable = fixtures.filter { ($0.title ?? "").hasPrefix("M1 Fixture Resizable") && $0.runtimeHandle != nil }
        let handles = Set(resizable.compactMap(\.runtimeHandle))
        #expect(handles.count >= 2)
    }

    @Test("setFrame moves only the selected fixture and restores original frame", .enabled(if: runWindowIntegration))
    func setFrameMovesOnlySelectedFixtureAndRestores() async throws {
        let service = NativeWindowService()
        let fixtures = try await requireFixtureDescriptors(using: service)

        let selected = try #require(descriptor(named: Self.fixtureResizableA, in: fixtures, requiresHandle: true))
        let untouched = try #require(descriptor(named: Self.fixtureResizableB, in: fixtures, requiresHandle: true))
        let handle = try #require(selected.runtimeHandle)
        let original = try #require(selected.frame?.cgRect)
        let untouchedOriginal = try #require(untouched.frame?.cgRect)

        let requested = CGRect(x: original.minX + 36,
                               y: original.minY + 28,
                               width: max(320, original.width - 24),
                               height: max(220, original.height - 18))

        var operationError: (any Error)?
        do {
            try await service.setFrame(requested, for: handle)
            let refreshed = try await service.refresh().filter { $0.bundleIdentifier == Self.fixtureBundleIdentifier }
            let moved = try #require(refreshed.first(where: { $0.id == selected.id }))
            let movedFrame = try #require(moved.frame?.cgRect)
            let untouchedAfter = try #require(refreshed.first(where: { $0.id == untouched.id }))
            let untouchedFrameAfter = try #require(untouchedAfter.frame?.cgRect)
            #expect(WindowGeometry.approximatelyEqual(movedFrame, requested, tolerance: 2))
            #expect(WindowGeometry.approximatelyEqual(untouchedFrameAfter, untouchedOriginal, tolerance: 2))
        } catch {
            operationError = error
        }

        do {
            // A rejected transaction invalidates its generation. Reacquire only this fixture's
            // verified current identity for cleanup instead of retrying a revoked handle.
            let current = try await service.refresh().first { $0.id == selected.id && $0.processID == selected.processID }
            let restoreHandle = try #require(current?.runtimeHandle)
            try await service.setFrame(original, for: restoreHandle)
            let refreshed = try await service.refresh().filter { $0.bundleIdentifier == Self.fixtureBundleIdentifier }
            let restored = try #require(refreshed.first(where: { $0.id == selected.id })?.frame?.cgRect)
            #expect(WindowGeometry.approximatelyEqual(restored, original, tolerance: 2))
        } catch {
            throw NativeWindowAssertionError(message: "Failed to restore '\(Self.fixtureResizableA)': \(error)")
        }

        if let operationError {
            throw operationError
        }
    }

    @Test("activate focuses selected fixture with AX readback", .enabled(if: runWindowIntegration))
    func activateFocusesSelectedFixture() async throws {
        let service = NativeWindowService()
        let fixtures = try await requireFixtureDescriptors(using: service)
        let selected = try #require(descriptor(named: Self.fixtureResizableA, in: fixtures, requiresHandle: true))
        let handle = try #require(selected.runtimeHandle)

        try await service.activate(handle)
        let focused = try #require(try focusedWindowSnapshot(processID: selected.processID))
        #expect(focused.title == selected.title)
        if let expected = selected.frame?.cgRect, let actual = focused.frame {
            #expect(WindowGeometry.approximatelyEqual(actual, expected, tolerance: 2))
        }
    }

    @Test("Overlapping equal title+geometry fixtures remain ambiguous (no runtime handles)", .enabled(if: runWindowIntegration))
    func overlappingFixturesStayAmbiguous() async throws {
        let service = NativeWindowService()
        let fixtures = try await requireFixtureDescriptors(using: service)
        let overlaps = try overlappingDescriptors(in: fixtures)
        #expect(overlaps.count >= 2)
        let overlapReference = try #require(overlaps.first?.frame?.cgRect)

        for window in overlaps {
            #expect(window.runtimeHandle == nil)
            let frame = try #require(window.frame?.cgRect)
            #expect(WindowGeometry.approximatelyEqual(frame, overlapReference, tolerance: 1))
        }
    }

    @Test("Fixed-size fixture advertises resize constraints and rejects resize", .enabled(if: runWindowIntegration))
    func fixedSizeFixtureRejectsResize() async throws {
        let service = NativeWindowService()
        let fixtures = try await requireFixtureDescriptors(using: service)
        let fixed = try #require(descriptor(named: Self.fixtureFixed, in: fixtures, requiresHandle: true))
        let handle = try #require(fixed.runtimeHandle)
        let frame = try #require(fixed.frame?.cgRect)

        #expect(fixed.capabilities.canSetSize == false)
        let requested = CGRect(x: frame.minX, y: frame.minY, width: frame.width + 80, height: frame.height + 60)
        try await expectAetherError(.unsupported) {
            try await service.setFrame(requested, for: handle)
        }
    }

    @Test("Forged/stale generation handles are rejected", .enabled(if: runWindowIntegration))
    func forgedGenerationHandleIsRejected() async throws {
        let service = NativeWindowService()
        let fixtures = try await requireFixtureDescriptors(using: service)
        let selected = try #require(descriptor(named: Self.fixtureResizableA, in: fixtures, requiresHandle: true))
        let handle = try #require(selected.runtimeHandle)
        let frame = try #require(selected.frame?.cgRect)
        let forged = RuntimeWindowHandle(windowID: handle.windowID, processID: handle.processID, generation: UUID())

        try await expectAetherError(.notFound) {
            try await service.setFrame(frame, for: forged)
        }
        try await expectAetherError(.notFound) {
            try await service.activate(forged)
        }
    }

    @Test("Invalid geometry built from observed descriptor is rejected", .enabled(if: runWindowIntegration))
    func invalidGeometryIsRejected() async throws {
        let service = NativeWindowService()
        let fixtures = try await requireFixtureDescriptors(using: service)
        let selected = try #require(descriptor(named: Self.fixtureResizableA, in: fixtures, requiresHandle: true))
        let handle = try #require(selected.runtimeHandle)
        let frame = try #require(selected.frame?.cgRect)

        let invalid = CGRect(x: frame.minX, y: frame.minY, width: .nan, height: frame.height)
        try await expectAetherError(.invalidState) {
            try await service.setFrame(invalid, for: handle)
        }
    }

    @Test("setFrame()/activate() honor pre-cancellation", .enabled(if: runWindowIntegration))
    func operationsHonorPreCancellation() async throws {
        let service = NativeWindowService()
        let fixtures = try await requireFixtureDescriptors(using: service)
        let selected = try #require(descriptor(named: Self.fixtureResizableA, in: fixtures, requiresHandle: true))
        let handle = try #require(selected.runtimeHandle)
        let frame = try #require(selected.frame?.cgRect)

        let cancelledSetFrame = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await service.setFrame(frame, for: handle)
        }
        await #expect(throws: CancellationError.self) {
            try await cancelledSetFrame.value
        }

        let cancelledActivate = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await service.activate(handle)
        }
        await #expect(throws: CancellationError.self) {
            try await cancelledActivate.value
        }
    }

    @Test("Closing disposable fixture invalidates the old runtime handle", .enabled(if: runWindowIntegration))
    func closingDisposableFixtureInvalidatesHandle() async throws {
        let service = NativeWindowService()
        let fixtures = try await requireFixtureDescriptors(using: service)
        let disposable = try #require(fixtures.first {
            $0.title == "M1 Fixture Resizable Disposable" && $0.runtimeHandle != nil
        })
        let handle = try #require(disposable.runtimeHandle)
        let title = try #require(disposable.title)
        #expect(title.hasSuffix("Disposable"))

        try closeWindowViaAX(processID: disposable.processID, title: title, frame: disposable.frame?.cgRect)
        try await waitForWindowDisappearance(windowID: disposable.id, using: service)
        try await expectAetherError(.notFound) {
            try await service.activate(handle)
        }
    }

    @Test("Correlation uses real desktop snapshots and stays conservative", .enabled(if: runWindowIntegration))
    func correlationUsesRealSnapshots() async throws {
        let service = NativeWindowService()
        let fixtures = try await requireFixtureDescriptors(using: service)

        let processIDs = Set(fixtures.map(\.processID))
        let accessibility = try collectAXMetadata(processIDs: processIDs)
        _ = try #require(accessibility.first, "No AX metadata could be read from the running TestLab fixtures")

        let matches = WindowCorrelation.matches(native: fixtures, accessibility: accessibility)
        for (windowID, index) in matches {
            let native = try #require(fixtures.first(where: { $0.id == windowID }))
            let ax = accessibility[index]
            #expect(native.processID == ax.processID)
            if let nativeFrame = native.frame?.cgRect, let axFrame = ax.frame {
                #expect(WindowGeometry.approximatelyEqual(nativeFrame, axFrame, tolerance: 2))
            }
            if let title = native.title, !title.isEmpty,
               let axTitle = ax.title, !axTitle.isEmpty {
                #expect(title == axTitle)
            }
        }

        let overlaps = try overlappingDescriptors(in: fixtures)
        #expect(overlaps.count >= 2)
        for overlap in overlaps {
            #expect(matches[overlap.id] == nil)
        }
    }

    private func requireFixtureDescriptors(using service: NativeWindowService) async throws -> [WindowDescriptor] {
        try #require(!IsSecureEventInputEnabled(),
                     "Unlock the desktop and finish secure input before running live fixture tests")
        try #require(AXIsProcessTrusted(),
                         "Accessibility permission is required for live window integration tests")
        _ = try #require(
            NSRunningApplication.runningApplications(withBundleIdentifier: Self.fixtureBundleIdentifier)
                .first(where: { !$0.isTerminated }),
            "Launch external TestLab (bundle \(Self.fixtureBundleIdentifier)) with --m1-fixtures"
        )

        // AppKit can expose transient AX proxies while a freshly launched app initializes.
        // Await actual correlated fixtures, never a fixed delay or an assumed success.
        let deadline = ContinuousClock.now.advanced(by: .seconds(10))
        var fixtures: [WindowDescriptor] = []
        while true {
            fixtures = try await service.refresh().filter { $0.bundleIdentifier == Self.fixtureBundleIdentifier }
            let names = Set(fixtures.compactMap(\.title))
            if names.isSuperset(of: [Self.fixtureResizableA, Self.fixtureResizableB, Self.fixtureFixed]),
               try overlappingDescriptors(in: fixtures).count >= 2 { break }
            if ContinuousClock.now >= deadline { break }
            try await Task.sleep(for: .milliseconds(80))
        }
        _ = try #require(fixtures.first,
                         "No TestLab windows discovered. Keep TestLab running with --m1-fixtures")

        _ = try #require(descriptor(named: Self.fixtureResizableA, in: fixtures),
                         "Missing fixture '\(Self.fixtureResizableA)'")
        _ = try #require(descriptor(named: Self.fixtureResizableB, in: fixtures),
                         "Missing fixture '\(Self.fixtureResizableB)'")
        _ = try #require(descriptor(named: Self.fixtureFixed, in: fixtures),
                         "Missing fixture '\(Self.fixtureFixed)'")

        let overlapCount = try overlappingDescriptors(in: fixtures).count
        _ = try #require(overlapCount >= 2 ? overlapCount : nil,
                         "Need at least two '\(Self.fixtureOverlap)' windows with identical frame and title")

        return fixtures
    }

    /// CG titles can be redacted without Screen Recording. Identify the test-only overlap group
    /// from actual AX geometry/title, without assigning a unique identity to either CG row.
    private func overlappingDescriptors(in fixtures: [WindowDescriptor]) throws -> [WindowDescriptor] {
        let metadata = try collectAXMetadata(processIDs: Set(fixtures.map(\.processID)))
            .filter { $0.title == Self.fixtureOverlap }
        return fixtures.filter { native in
            metadata.contains { ax in
                guard native.processID == ax.processID, let frame = native.frame?.cgRect, let axFrame = ax.frame else { return false }
                return WindowGeometry.approximatelyEqual(frame, axFrame)
            }
        }
    }

    private func descriptor(
        named title: String,
        in descriptors: [WindowDescriptor],
        requiresHandle: Bool = false
    ) -> WindowDescriptor? {
        descriptors.first { descriptor in
            descriptor.title == title && (!requiresHandle || descriptor.runtimeHandle != nil)
        }
    }

    private func waitForWindowDisappearance(
        windowID: WindowID,
        using service: NativeWindowService,
        timeout: Duration = .seconds(4)
    ) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while clock.now < deadline {
            let descriptors = try await service.refresh()
            if descriptors.first(where: { $0.id == windowID }) == nil {
                return
            }
            try await Task.sleep(for: .milliseconds(80))
        }
        throw NativeWindowAssertionError(message: "Fixture window \(windowID.rawValue) did not disappear in time")
    }

    private func expectAetherError(
        _ expected: ExpectedAetherError,
        _ operation: () async throws -> Void
    ) async throws {
        do {
            try await operation()
            throw NativeWindowAssertionError(message: "Expected AetherError.\(expected.rawValue), but operation succeeded")
        } catch let error as AetherError {
            switch (expected, error) {
            case (.notFound, .notFound),
                 (.unsupported, .unsupported),
                 (.invalidState, .invalidState):
                return
            default:
                throw NativeWindowAssertionError(message: "Expected AetherError.\(expected.rawValue), got \(error)")
            }
        } catch {
            throw NativeWindowAssertionError(message: "Expected AetherError.\(expected.rawValue), got \(error)")
        }
    }

    private func focusedWindowSnapshot(processID: Int32) throws -> FocusedWindowSnapshot? {
        let app = AXUIElementCreateApplication(processID)
        _ = AXUIElementSetMessagingTimeout(app, 0.15)
        guard let focusedRef = try readAXAttribute(app, kAXFocusedWindowAttribute),
              CFGetTypeID(focusedRef) == AXUIElementGetTypeID() else {
            return nil
        }
        let focused = unsafeDowncast(focusedRef, to: AXUIElement.self)
        _ = AXUIElementSetMessagingTimeout(focused, 0.15)
        let title = try readAXAttribute(focused, kAXTitleAttribute) as? String
        let frame = try axFrame(of: focused)
        return FocusedWindowSnapshot(title: title, frame: frame)
    }

    private func closeWindowViaAX(processID: Int32, title: String, frame: CGRect?) throws {
        let windows = try axWindows(processID: processID)
        let target = try #require(
            try matchingWindowElement(in: windows, title: title, frame: frame),
            "Unable to locate disposable fixture '\(title)' in AX window list"
        )
        guard let closeButtonRef = try readAXAttribute(target, kAXCloseButtonAttribute),
              CFGetTypeID(closeButtonRef) == AXUIElementGetTypeID() else {
            throw NativeWindowAssertionError(message: "AX close button is unavailable for '\(title)'")
        }
        let closeButton = unsafeDowncast(closeButtonRef, to: AXUIElement.self)
        let result = AXUIElementPerformAction(closeButton, kAXPressAction as CFString)
        guard result == .success else {
            throw NativeWindowAssertionError(message: "AX close action failed for '\(title)' with AXError \(result.rawValue)")
        }
    }

    private func matchingWindowElement(
        in windows: [AXUIElement],
        title: String,
        frame: CGRect?
    ) throws -> AXUIElement? {
        for window in windows {
            let candidateTitle = try readAXAttribute(window, kAXTitleAttribute) as? String
            guard candidateTitle == title else { continue }
            if let frame {
                guard let candidateFrame = try axFrame(of: window),
                      WindowGeometry.approximatelyEqual(candidateFrame, frame, tolerance: 2) else { continue }
            }
            return window
        }
        return nil
    }

    private func collectAXMetadata(processIDs: Set<Int32>) throws -> [AXWindowMetadata] {
        var metadata: [AXWindowMetadata] = []
        for processID in processIDs.sorted() {
            for window in try axWindows(processID: processID) {
                let frame = try axFrame(of: window)
                let title = try readAXAttribute(window, kAXTitleAttribute) as? String
                let isMinimized = (try readAXAttribute(window, kAXMinimizedAttribute) as? NSNumber)?.boolValue ?? false
                let actions = try actionNames(of: window)
                let canRaise = actions.contains(kAXRaiseAction)
                let canSetPosition = try isSettable(window, attribute: kAXPositionAttribute)
                let canSetSize = try isSettable(window, attribute: kAXSizeAttribute)
                let canSetMain = try isSettable(window, attribute: kAXMainAttribute)
                metadata.append(
                    AXWindowMetadata(
                        processID: processID,
                        frame: frame,
                        title: title,
                        isMinimized: isMinimized,
                        capabilities: WindowCapabilities(
                            canReadFrame: frame != nil,
                            canSetPosition: canSetPosition,
                            canSetSize: canSetSize,
                            canFocus: canRaise && canSetMain
                        )
                    )
                )
            }
        }
        return metadata
    }

    private func axWindows(processID: Int32) throws -> [AXUIElement] {
        let app = AXUIElementCreateApplication(processID)
        _ = AXUIElementSetMessagingTimeout(app, 0.15)
        guard let windows = try readAXAttribute(app, kAXWindowsAttribute) as? [AXUIElement] else {
            return []
        }
        for window in windows {
            _ = AXUIElementSetMessagingTimeout(window, 0.15)
        }
        return windows
    }

    private func actionNames(of element: AXUIElement) throws -> [String] {
        var value: CFArray?
        let result = AXUIElementCopyActionNames(element, &value)
        switch result {
        case .success:
            return value as? [String] ?? []
        case .attributeUnsupported, .noValue:
            return []
        default:
            throw NativeWindowAssertionError(message: "AX action query failed with AXError \(result.rawValue)")
        }
    }

    private func isSettable(_ element: AXUIElement, attribute: String) throws -> Bool {
        var value = DarwinBoolean(false)
        let result = AXUIElementIsAttributeSettable(element, attribute as CFString, &value)
        switch result {
        case .success:
            return value.boolValue
        case .attributeUnsupported:
            return false
        default:
            throw NativeWindowAssertionError(message: "AX settable check for '\(attribute)' failed with AXError \(result.rawValue)")
        }
    }

    private func readAXAttribute(_ element: AXUIElement, _ attribute: String) throws -> CFTypeRef? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        switch result {
        case .success:
            return value
        case .attributeUnsupported, .noValue:
            return nil
        default:
            throw NativeWindowAssertionError(message: "AX read '\(attribute)' failed with AXError \(result.rawValue)")
        }
    }

    private func axFrame(of element: AXUIElement) throws -> CGRect? {
        guard let positionRef = try readAXAttribute(element, kAXPositionAttribute),
              let sizeRef = try readAXAttribute(element, kAXSizeAttribute),
              CFGetTypeID(positionRef) == AXValueGetTypeID(),
              CFGetTypeID(sizeRef) == AXValueGetTypeID() else {
            return nil
        }

        let positionValue = unsafeDowncast(positionRef, to: AXValue.self)
        let sizeValue = unsafeDowncast(sizeRef, to: AXValue.self)
        guard AXValueGetType(positionValue) == .cgPoint,
              AXValueGetType(sizeValue) == .cgSize else {
            return nil
        }

        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue, .cgPoint, &point),
              AXValueGetValue(sizeValue, .cgSize, &size) else {
            return nil
        }

        let frame = CGRect(origin: point, size: size)
        return WindowGeometry.isValid(frame) ? frame : nil
    }
}

private enum ExpectedAetherError: String {
    case notFound
    case unsupported
    case invalidState
}

private struct FocusedWindowSnapshot {
    let title: String?
    let frame: CGRect?
}

private struct NativeWindowAssertionError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}