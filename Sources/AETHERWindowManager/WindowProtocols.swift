import Foundation
import AETHERShared

@MainActor
public protocol WindowDiscovering {
    func refresh() async throws -> [WindowDescriptor]
}

@MainActor
public protocol WindowControlling {
    func setFrame(_ frame: CGRect, for window: RuntimeWindowHandle) async throws
    func activate(_ window: RuntimeWindowHandle) async throws
}

public protocol DisplayDiscovering: Sendable {
    func displays() async -> [DisplaySnapshot]
}

public struct DisplaySnapshot: Sendable, Equatable {
    public let id: DisplayID
    public let bounds: CodableRect
    public let scale: Double
    public let refreshRate: Double
    public let isMain: Bool
}
