import Foundation
import AppKit
import ApplicationServices
import AETHERShared

@MainActor
public final class AccessibilityWindowController: WindowControlling {
    private let service: NativeWindowService

    public init(service: NativeWindowService = .shared) { self.service = service }

    public func setFrame(_ frame: CGRect, for window: RuntimeWindowHandle) async throws {
        try await service.setFrame(frame, for: window)
    }

    public func activate(_ window: RuntimeWindowHandle) async throws {
        try await service.activate(window)
    }
}
