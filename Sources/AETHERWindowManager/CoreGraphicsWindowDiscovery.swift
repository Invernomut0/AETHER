import Foundation
import CoreGraphics
import AppKit
import AETHERShared

@MainActor
public final class CoreGraphicsWindowDiscovery: WindowDiscovering {
    private let service: NativeWindowService

    public init(service: NativeWindowService = .shared) { self.service = service }

    public func refresh() async throws -> [WindowDescriptor] {
        try await service.refresh()
    }
}
