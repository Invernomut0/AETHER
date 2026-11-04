import Foundation
import AETHERShared

public struct CaptureSessionID: Hashable, Sendable {
    public let rawValue: UUID
    public init(rawValue: UUID = UUID()) { self.rawValue = rawValue }
}

public struct CapturedFrameMetadata: Sendable {
    public let timestamp: Double
    public let width: Int
    public let height: Int
    public let isComplete: Bool
}
