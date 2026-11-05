import Foundation
import AppKit
import AETHERShared

struct WindowProcessSnapshot: Sendable {
    let id: Int32
    let launchDate: Date?
    let bundleIdentifier: String?
    let name: String
}

/// MainActor façade: AppKit stays here; all blocking AX IPC and AX references stay in the actor.
@MainActor
public final class NativeWindowService: WindowDiscovering, WindowControlling {
    public static let shared = NativeWindowService()
    private let session = WindowAccessibilitySession()
    private var activeWindows: Set<WindowID> = []
    private var confirmedClosures: [(handle: RuntimeWindowHandle, launchDate: Date)] = []

    public init() {}

    public func refresh() async throws -> [WindowDescriptor] {
        let windows = try await session.refresh(processes: processes())
        // A reappearing/reused native ID revokes its old closure receipt.
        let ids = Set(windows.map(\.id))
        confirmedClosures.removeAll { ids.contains($0.handle.windowID) }
        return windows
    }

    /// Read-only revalidation of a registered generation, including current AX/CG correlation.
    public func validatedWindow(_ handle: RuntimeWindowHandle) async throws -> WindowDescriptor {
        try await session.validatedWindow(handle, process: process(handle.processID))
    }

    public func setFrame(_ frame: CGRect, for window: RuntimeWindowHandle) async throws {
        try Task.checkCancellation()
        try beginOperation(window.windowID)
        defer { activeWindows.remove(window.windowID) }
        try await session.setFrame(frame, for: window, process: process(window.processID))
    }

    /// Requests public AX close for this registered generation, then verifies native disappearance.
    /// Success means the exact ID/PID is absent from CG's full inventory, including off-screen
    /// windows. An unsaved sheet/refusal fails within a two-second verification deadline.
    /// Before AXPress, cancellation throws CancellationError without sending close. Once AXPress
    /// is attempted, cancellation/failure throws NativeWindowCloseError.outcomeUnconfirmed:
    /// the request may still close the window and cannot be undone. Never retry automatically.
    public func close(_ handle: RuntimeWindowHandle) async throws {
        try Task.checkCancellation()
        try beginOperation(handle.windowID)
        defer { activeWindows.remove(handle.windowID) }
        let snapshot = try process(handle.processID)
        try await session.close(handle, process: snapshot) { [self] in
            try process(handle.processID)
        }
        if let launchDate = snapshot.launchDate {
            confirmedClosures.removeAll { $0.handle.windowID == handle.windowID }
            confirmedClosures.append((handle, launchDate))
            if confirmedClosures.count > 128 { confirmedClosures.removeFirst() }
        }
    }

    /// Independent, read-only MainActor CG check for animation after successful close(_:).
    /// Requires an exact closure receipt from this service (the latest 128 are retained).
    /// Unknown/forged generations, reused IDs/PIDs and enumeration failures throw, not `true`.
    /// No AX IPC, visibility or minimized-state inference is used; recheck while animating.
    public func isWindowClosed(_ handle: RuntimeWindowHandle) throws -> Bool {
        guard let receipt = confirmedClosures.first(where: { $0.handle == handle }) else {
            throw AetherError.notFound("No confirmed close for this runtime generation")
        }
        if let app = NSRunningApplication(processIdentifier: handle.processID), !app.isTerminated,
           app.launchDate != receipt.launchDate {
            throw AetherError.notFound("The owning process identity changed")
        }
        return try !NativeWindowInventory.contains(handle)
    }

    public func activate(_ window: RuntimeWindowHandle) async throws {
        try Task.checkCancellation()
        try beginOperation(window.windowID)
        defer { activeWindows.remove(window.windowID) }
        let snapshot = try process(window.processID)
        try await session.raise(window, process: snapshot)
        try Task.checkCancellation()
        guard let app = NSRunningApplication(processIdentifier: window.processID),
              app.launchDate == snapshot.launchDate, app.activate(options: []) else {
            throw AetherError.operationFailed("Application activation failed")
        }
        try await session.verifyFocus(window, process: snapshot)
    }

    /// MainActor reentrancy must not allow two commands to mutate the same native window.
    private func beginOperation(_ id: WindowID) throws {
        guard activeWindows.insert(id).inserted else {
            throw AetherError.invalidState("Another operation already owns this window")
        }
    }

    private func processes() -> [WindowProcessSnapshot] {
        NSWorkspace.shared.runningApplications.filter { !$0.isTerminated }.map {
            WindowProcessSnapshot(id: $0.processIdentifier, launchDate: $0.launchDate,
                                  bundleIdentifier: $0.bundleIdentifier, name: $0.localizedName ?? "Unknown")
        }
    }

    private func process(_ id: Int32) throws -> WindowProcessSnapshot {
        guard let app = NSRunningApplication(processIdentifier: id), !app.isTerminated else {
            throw AetherError.notFound("The owning application has terminated")
        }
        return WindowProcessSnapshot(id: id, launchDate: app.launchDate,
                                     bundleIdentifier: app.bundleIdentifier, name: app.localizedName ?? "Unknown")
    }
}