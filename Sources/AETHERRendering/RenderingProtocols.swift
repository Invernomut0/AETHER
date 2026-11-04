import Foundation
import AETHERShared

public struct RendererDiagnostics: Sendable {
    public var isAvailable: Bool
    public var framesPresented: UInt64
    public var averageFrameTimeMilliseconds: Double
    public var allocatedTextureBytes: UInt64
    public var lastError: String?
}

public protocol RenderingEngine: Sendable {
    func initialize() async throws
    func suspend() async
    func resume() async throws
    func diagnostics() async -> RendererDiagnostics
}
