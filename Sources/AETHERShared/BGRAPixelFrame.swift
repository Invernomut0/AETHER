import Foundation

/// Immutable CPU-owned pixels. Framework buffers never cross isolation boundaries.
/// A frame is bounded to 1600 pixels per edge; bytes include the producer's row padding.
public struct BGRAPixelFrame: Sendable {
    public static let maximumDimension = 1600
    public let width: Int
    public let height: Int
    public let bytesPerRow: Int
    public let bytes: Data

    public init(width: Int, height: Int, bytesPerRow: Int, bytes: Data) throws {
        guard width > 0, height > 0,
              width <= Self.maximumDimension, height <= Self.maximumDimension,
              bytesPerRow >= width * 4, bytesPerRow <= Self.maximumDimension * 4 + 4096,
              bytes.count == bytesPerRow * height else {
            throw AetherError.invalidState("Invalid or oversized BGRA frame")
        }
        self.width = width
        self.height = height
        self.bytesPerRow = bytesPerRow
        self.bytes = bytes
    }
}