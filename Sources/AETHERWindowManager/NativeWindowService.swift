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

    public init() {}

    public func refresh() async throws -> [WindowDescriptor] {
        try await session.refresh(processes: processes())
    }

    public func setFrame(_ frame: CGRect, for window: RuntimeWindowHandle) async throws {
        try Task.checkCancellation()
        try beginOperation(window.windowID)
        defer { activeWindows.remove(window.windowID) }
        try await session.setFrame(frame, for: window, process: process(window.processID))
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