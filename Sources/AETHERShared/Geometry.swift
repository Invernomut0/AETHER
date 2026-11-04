import Foundation
import CoreGraphics

public struct CodablePoint: Codable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
    public var cgPoint: CGPoint { CGPoint(x: x, y: y) }
}

public struct CodableSize: Codable, Hashable, Sendable {
    public var width: Double
    public var height: Double
    public init(width: Double, height: Double) { self.width = width; self.height = height }
    public var cgSize: CGSize { CGSize(width: width, height: height) }
}

public struct CodableRect: Codable, Hashable, Sendable {
    public var origin: CodablePoint
    public var size: CodableSize
    public init(x: Double, y: Double, width: Double, height: Double) {
        origin = CodablePoint(x: x, y: y)
        size = CodableSize(width: width, height: height)
    }
    public init(_ rect: CGRect) {
        self.init(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height)
    }
    public var cgRect: CGRect {
        CGRect(origin: origin.cgPoint, size: size.cgSize)
    }
}
