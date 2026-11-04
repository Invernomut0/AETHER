import Foundation
import CoreGraphics
import ApplicationServices
import OSLog
import AETHERShared

/// Owns every AX reference. Bounded synchronous IPC runs off MainActor; only value snapshots escape.
actor WindowAccessibilitySession {
    private struct Entry {
        let handle: RuntimeWindowHandle
        let element: AXUIElement
        let launchDate: Date
    }

    private struct Candidate {
        let element: AXUIElement
        let metadata: AXWindowMetadata
    }

    private let log = Logger(subsystem: "com.aether.desktop", category: "windows")
    private var entries: [WindowID: Entry] = [:]
    private let clock = ContinuousClock()

    func refresh(processes: [WindowProcessSnapshot]) throws -> [WindowDescriptor] {
        do {
            try Task.checkCancellation()
            let native = try nativeWindows(processes: processes)
            guard AXIsProcessTrusted() else {
                entries.removeAll()
                return native
            }
            let deadline = clock.now.advanced(by: .seconds(5))
            let pids = Set(native.map(\.processID))
            var candidates: [Candidate] = []
            var unavailable = 0
            for process in processes where pids.contains(process.id) {
                try Task.checkCancellation()
                if clock.now >= deadline { unavailable += 1; break }
                do {
                    candidates += try accessibilityWindows(pid: process.id, deadline: deadline)
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    unavailable += 1
                }
            }
            let matches = WindowCorrelation.matches(native: native, accessibility: candidates.map(\.metadata))
            var next: [WindowID: Entry] = [:]
            var result: [WindowDescriptor] = []
            for window in native {
                guard let index = matches[window.id],
                      let launchDate = processes.first(where: { $0.id == window.processID })?.launchDate else {
                    result.append(window)
                    continue
                }
                let candidate = candidates[index]
                let old = entries[window.id]
                let handle: RuntimeWindowHandle
                if let old, old.handle.processID == window.processID, old.launchDate == launchDate,
                   CFEqual(old.element, candidate.element) {
                    handle = old.handle
                } else {
                    handle = RuntimeWindowHandle(windowID: window.id, processID: window.processID)
                }
                next[window.id] = Entry(handle: handle, element: candidate.element, launchDate: launchDate)
                result.append(WindowDescriptor(
                    id: window.id, processID: window.processID, bundleIdentifier: window.bundleIdentifier,
                    applicationName: window.applicationName, title: candidate.metadata.title ?? window.title,
                    frame: window.frame, displayID: window.displayID, isOnScreen: window.isOnScreen,
                    isMinimized: candidate.metadata.isMinimized, capabilities: candidate.metadata.capabilities,
                    runtimeHandle: handle
                ))
            }
            try Task.checkCancellation()
            entries = next
            log.info("Discovery: \(native.count) native, \(next.count) correlated, \(unavailable) unavailable applications")
            return result
        } catch {
            entries.removeAll()
            throw error
        }
    }

    func setFrame(_ frame: CGRect, for handle: RuntimeWindowHandle, process: WindowProcessSnapshot) async throws {
        guard WindowGeometry.isValid(frame) else {
            throw AetherError.invalidState("Window geometry must be finite with positive dimensions")
        }
        let deadline = clock.now.advanced(by: .seconds(3))
        let candidate = try resolve(handle, process: process, deadline: deadline)
        guard let original = candidate.metadata.frame else { throw AetherError.unsupported("AX frame is unreadable") }
        let move = abs(original.minX - frame.minX) > 1 || abs(original.minY - frame.minY) > 1
        let resize = abs(original.width - frame.width) > 1 || abs(original.height - frame.height) > 1
        guard (!move || candidate.metadata.capabilities.canSetPosition),
              (!resize || candidate.metadata.capabilities.canSetSize) else {
            throw AetherError.unsupported("The selected window does not support the requested position or size change")
        }
        var observed: CGRect?
        do {
            // Move before growing: AppKit may clamp a resize against the current display edge.
            // Position is applied again after sizing because applications can adjust it on resize.
            if move { try writePosition(frame.origin, to: candidate.element, deadline: deadline) }
            if resize {
                try writeSize(frame.size, to: candidate.element, deadline: deadline)
                // AppKit/WindowServer may acknowledge AX before CG publishes the new bounds.
                // Settle size first: resizing can itself adjust the origin.
                while true {
                    try checkpoint(deadline)
                    let ax = try axFrame(candidate.element, deadline: deadline)
                    observed = ax
                    let cg = try nativeWindows(processes: [process]).first { $0.id == handle.windowID }?.frame?.cgRect
                    if let ax, let cg, abs(ax.width - frame.width) <= 1, abs(ax.height - frame.height) <= 1,
                       abs(cg.width - frame.width) <= 1, abs(cg.height - frame.height) <= 1 { break }
                    try await Task.sleep(for: .milliseconds(40))
                    try validateInFlight(handle, element: candidate.element, deadline: deadline)
                }
            }
            if (move || resize) && candidate.metadata.capabilities.canSetPosition {
                try writePosition(frame.origin, to: candidate.element, deadline: deadline)
            }
            var confirmed = false
            while true {
                try checkpoint(deadline)
                     observed = try axFrame(candidate.element, deadline: deadline)
                let cg = try nativeWindows(processes: [process]).first { $0.id == handle.windowID }?.frame?.cgRect
                let agrees = observed.map { WindowGeometry.approximatelyEqual($0, frame) } == true
                    && cg.map { WindowGeometry.approximatelyEqual($0, frame) } == true
                if agrees && confirmed { return }
                confirmed = agrees
                try await Task.sleep(for: .milliseconds(40))
                try validateInFlight(handle, element: candidate.element, deadline: deadline)
            }
        } catch {
            // AX geometry writes are not atomic. Do not blindly roll back over user changes.
            entries.removeValue(forKey: handle.windowID)
            log.error("Geometry operation failed; generation invalidated. Native state may be partially changed.")
            if error is CancellationError { throw error }
            throw AetherError.operationFailed("Geometry was rejected or timed out; the native frame may be partially changed. Requested \(frame), observed \(String(describing: observed)). Refresh before retrying. \(error)")
        }
    }

    /// During an owned geometry transaction CG can lag AX. Validate membership, not old geometry.
    private func validateInFlight(_ handle: RuntimeWindowHandle, element: AXUIElement,
                                  deadline: ContinuousClock.Instant) throws {
        try checkpoint(deadline)
        guard AXIsProcessTrusted() else {
            entries.removeAll()
            throw AetherError.permissionDenied("Accessibility permission was revoked")
        }
        guard entries[handle.windowID]?.handle == handle,
              let current = try read(application(handle.processID), kAXWindowsAttribute, deadline: deadline) as? [AXUIElement],
              current.contains(where: { CFEqual($0, element) }) else {
            throw AetherError.notFound("The window generation was invalidated during the operation")
        }
    }

    func raise(_ handle: RuntimeWindowHandle, process: WindowProcessSnapshot) throws {
        let deadline = clock.now.advanced(by: .seconds(2))
        let candidate = try resolve(handle, process: process, deadline: deadline)
        guard candidate.metadata.capabilities.canFocus else {
            throw AetherError.unsupported("The selected window cannot be raised and focused")
        }
        try checkpoint(deadline)
        try requireSuccess(AXUIElementPerformAction(candidate.element, kAXRaiseAction as CFString), operation: "Raise selected window")
        try checkpoint(deadline)
        try requireSuccess(AXUIElementSetAttributeValue(candidate.element, kAXMainAttribute as CFString, kCFBooleanTrue), operation: "Select main window")
    }

    func verifyFocus(_ handle: RuntimeWindowHandle, process: WindowProcessSnapshot) async throws {
        let deadline = clock.now.advanced(by: .seconds(2))
        do {
            while true {
                let candidate = try resolve(handle, process: process, deadline: deadline)
                let app = try application(process.id)
                if let focused = try read(app, kAXFocusedWindowAttribute, deadline: deadline),
                   CFGetTypeID(focused) == AXUIElementGetTypeID(), CFEqual(focused, candidate.element) { return }
                try await Task.sleep(for: .milliseconds(40))
            }
        } catch {
            entries.removeValue(forKey: handle.windowID)
            throw error
        }
    }

    private func resolve(_ handle: RuntimeWindowHandle, process: WindowProcessSnapshot,
                         deadline: ContinuousClock.Instant) throws -> Candidate {
        try checkpoint(deadline)
        guard AXIsProcessTrusted() else {
            entries.removeAll()
            throw AetherError.permissionDenied("Accessibility permission is required")
        }
        guard let entry = entries[handle.windowID], entry.handle == handle,
              process.id == handle.processID, process.launchDate == entry.launchDate else {
            throw AetherError.notFound("Stale or unknown runtime window handle; refresh discovery")
        }
        do {
            let native = try nativeWindows(processes: [process]).filter { $0.processID == process.id }
            let candidates = try accessibilityWindows(pid: process.id, deadline: deadline)
            let matches = WindowCorrelation.matches(native: native, accessibility: candidates.map(\.metadata))
            guard let index = matches[handle.windowID], CFEqual(entry.element, candidates[index].element) else {
                throw AetherError.notFound("Window disappeared, changed identity or became ambiguous")
            }
            return candidates[index]
        } catch {
            entries.removeValue(forKey: handle.windowID)
            throw error
        }
    }

    private func nativeWindows(processes: [WindowProcessSnapshot]) throws -> [WindowDescriptor] {
        guard let rows = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            throw AetherError.resourceUnavailable("CoreGraphics window enumeration failed")
        }
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 32)
        var count: UInt32 = 0
        let displaysAvailable = CGGetActiveDisplayList(UInt32(displayIDs.count), &displayIDs, &count) == .success
        let displays = displaysAvailable ? Array(displayIDs.prefix(Int(count))) : []
        return rows.compactMap { row in
            guard let number = row[kCGWindowNumber as String] as? NSNumber,
                  let pid = row[kCGWindowOwnerPID as String] as? NSNumber, pid.int32Value > 0,
                  (row[kCGWindowLayer as String] as? NSNumber)?.intValue == 0,
                  let dictionary = row[kCGWindowBounds as String] as? NSDictionary,
                  let frame = CGRect(dictionaryRepresentation: dictionary), WindowGeometry.isValid(frame) else { return nil }
            let process = processes.first { $0.id == pid.int32Value }
            let display = displays.max { left, right in
                area(frame.intersection(CGDisplayBounds(left))) < area(frame.intersection(CGDisplayBounds(right)))
            }.flatMap { area(frame.intersection(CGDisplayBounds($0))) > 0 ? DisplayID(rawValue: $0) : nil }
            return WindowDescriptor(
                id: WindowID(rawValue: number.uint32Value), processID: pid.int32Value,
                bundleIdentifier: process?.bundleIdentifier,
                applicationName: process?.name ?? row[kCGWindowOwnerName as String] as? String ?? "Unknown",
                title: row[kCGWindowName as String] as? String, frame: CodableRect(frame), displayID: display,
                isOnScreen: (row[kCGWindowIsOnscreen as String] as? NSNumber)?.boolValue ?? false,
                isMinimized: false, capabilities: WindowCapabilities(canReadFrame: true)
            )
        }
    }

    private func area(_ rect: CGRect) -> CGFloat { rect.isNull ? 0 : rect.width * rect.height }

    private func application(_ pid: Int32) throws -> AXUIElement {
        let app = AXUIElementCreateApplication(pid)
        try requireSuccess(AXUIElementSetMessagingTimeout(app, 0.15), operation: "Set AX messaging timeout")
        return app
    }

    private func accessibilityWindows(pid: Int32, deadline: ContinuousClock.Instant) throws -> [Candidate] {
        try checkpoint(deadline)
        let app = try application(pid)
        guard let elements = try read(app, kAXWindowsAttribute, deadline: deadline) as? [AXUIElement] else { return [] }
        // Never control an app with an incomplete window inventory.
        guard elements.count <= 128 else { throw AetherError.resourceUnavailable("AX window inventory exceeds safety limit") }
        var result: [Candidate] = []
        for element in elements {
            try checkpoint(deadline)
            try requireSuccess(AXUIElementSetMessagingTimeout(element, 0.15), operation: "Set AX window timeout")
            guard try read(element, kAXRoleAttribute, deadline: deadline) as? String == kAXWindowRole else { continue }
            let frame = try axFrame(element, deadline: deadline)
            let title = try read(element, kAXTitleAttribute, deadline: deadline) as? String
            let minimized = (try read(element, kAXMinimizedAttribute, deadline: deadline) as? NSNumber)?.boolValue ?? false
            var actions: CFArray?
            try checkpoint(deadline)
            let actionsResult = AXUIElementCopyActionNames(element, &actions)
            if actionsResult == .cannotComplete { throw AetherError.timeout("AX action query timed out") }
            let canRaise = (actions as? [String])?.contains(kAXRaiseAction) == true
            let position = try settable(element, kAXPositionAttribute, deadline: deadline)
            let size = try settable(element, kAXSizeAttribute, deadline: deadline)
            let main = try settable(element, kAXMainAttribute, deadline: deadline)
            result.append(Candidate(element: element, metadata: AXWindowMetadata(
                processID: pid, frame: frame, title: title, isMinimized: minimized,
                capabilities: WindowCapabilities(canReadFrame: frame != nil, canSetPosition: position,
                                                 canSetSize: size, canFocus: canRaise && main)
            )))
        }
        return result
    }

    private func read(_ element: AXUIElement, _ attribute: String, deadline: ContinuousClock.Instant) throws -> CFTypeRef? {
        try checkpoint(deadline)
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        if error == .cannotComplete { throw AetherError.timeout("AX attribute query timed out") }
        return error == .success ? value : nil
    }

    private func axFrame(_ element: AXUIElement, deadline: ContinuousClock.Instant) throws -> CGRect? {
        guard let positionRef = try read(element, kAXPositionAttribute, deadline: deadline),
              let sizeRef = try read(element, kAXSizeAttribute, deadline: deadline),
              CFGetTypeID(positionRef) == AXValueGetTypeID(), CFGetTypeID(sizeRef) == AXValueGetTypeID() else { return nil }
        // CF type IDs are verified before casting; these references remain actor-owned.
        let positionValue = unsafeDowncast(positionRef, to: AXValue.self)
        let sizeValue = unsafeDowncast(sizeRef, to: AXValue.self)
        guard AXValueGetType(positionValue) == .cgPoint, AXValueGetType(sizeValue) == .cgSize else { return nil }
        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue, .cgPoint, &point), AXValueGetValue(sizeValue, .cgSize, &size) else { return nil }
        let frame = CGRect(origin: point, size: size)
        return WindowGeometry.isValid(frame) ? frame : nil
    }

    private func settable(_ element: AXUIElement, _ attribute: String, deadline: ContinuousClock.Instant) throws -> Bool {
        try checkpoint(deadline)
        var value = DarwinBoolean(false)
        let error = AXUIElementIsAttributeSettable(element, attribute as CFString, &value)
        if error == .cannotComplete { throw AetherError.timeout("AX capability query timed out") }
        return error == .success && value.boolValue
    }

    private func writePosition(_ point: CGPoint, to element: AXUIElement, deadline: ContinuousClock.Instant) throws {
        try checkpoint(deadline)
        var point = point
        guard let value = AXValueCreate(.cgPoint, &point) else { throw AetherError.operationFailed("Cannot encode AX position") }
        try requireSuccess(AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, value), operation: "Set position")
    }

    private func writeSize(_ size: CGSize, to element: AXUIElement, deadline: ContinuousClock.Instant) throws {
        try checkpoint(deadline)
        var size = size
        guard let value = AXValueCreate(.cgSize, &size) else { throw AetherError.operationFailed("Cannot encode AX size") }
        try requireSuccess(AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, value), operation: "Set size")
    }

    private func checkpoint(_ deadline: ContinuousClock.Instant) throws {
        try Task.checkCancellation()
        guard clock.now < deadline else { throw AetherError.timeout("Window operation deadline exceeded") }
    }

    private func requireSuccess(_ error: AXError, operation: String) throws {
        guard error == .success else {
            if error == .cannotComplete { throw AetherError.timeout("\(operation): AX IPC timeout") }
            throw AetherError.operationFailed("\(operation): AX error \(error.rawValue)")
        }
    }
}