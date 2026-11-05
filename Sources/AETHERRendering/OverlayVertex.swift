/// One triangle-list vertex. Position is NDC; UV origin is the image's top left.
/// Two float2 fields match the Metal effect vertex's 16-byte stride.
public struct OverlayVertex: Sendable {
    public var position: SIMD2<Float>
    public var textureCoordinate: SIMD2<Float>

    public init(position: SIMD2<Float>, textureCoordinate: SIMD2<Float>) {
        self.position = position
        self.textureCoordinate = textureCoordinate
    }
}