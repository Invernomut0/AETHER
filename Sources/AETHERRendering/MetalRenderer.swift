import Foundation
import Metal
import AETHERShared

public actor MetalRenderer: RenderingEngine {
    private let provider: MetalDeviceProvider
    private var initialized = false
    private var framesPresented: UInt64 = 0
    private var lastError: String?

    public init(provider: MetalDeviceProvider = MetalDeviceProvider()) {
        self.provider = provider
    }

    public func initialize() async throws {
        _ = try provider.requireDevice()
        initialized = true
    }

    public func suspend() async { initialized = false }

    public func resume() async throws {
        try await initialize()
    }

    public func diagnostics() async -> RendererDiagnostics {
        RendererDiagnostics(
            isAvailable: initialized,
            framesPresented: framesPresented,
            averageFrameTimeMilliseconds: 0,
            allocatedTextureBytes: 0,
            lastError: lastError
        )
    }
}
