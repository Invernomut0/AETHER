import Foundation
import Metal
import AETHERShared

public final class MetalDeviceProvider: @unchecked Sendable {
    public let device: MTLDevice?

    public init() {
        self.device = MTLCreateSystemDefaultDevice()
    }

    public func requireDevice() throws -> MTLDevice {
        guard let device else {
            throw AetherError.resourceUnavailable("No compatible Metal device is available")
        }
        return device
    }
}
