import Foundation

/// Geometry shared by public AX and CG APIs, expressed in global top-left points (not pixels).
public enum WindowGeometry {
    public static func isValid(_ frame: CGRect) -> Bool {
        [frame.origin.x, frame.origin.y, frame.size.width, frame.size.height].allSatisfy(\.isFinite)
            && frame.size.width > 0 && frame.size.height > 0
    }

    public static func approximatelyEqual(_ lhs: CGRect, _ rhs: CGRect, tolerance: CGFloat = 1) -> Bool {
        isValid(lhs) && isValid(rhs)
            && abs(lhs.origin.x - rhs.origin.x) <= tolerance
            && abs(lhs.origin.y - rhs.origin.y) <= tolerance
            && abs(lhs.width - rhs.width) <= tolerance
            && abs(lhs.height - rhs.height) <= tolerance
    }

    /// AppKit's origin is bottom-left on the primary display; secondary coordinates may be negative.
    public static func fromAppKit(_ frame: CGRect, primaryDisplayHeight: CGFloat) -> CGRect {
        CGRect(x: frame.minX, y: primaryDisplayHeight - frame.maxY, width: frame.width, height: frame.height)
    }
}