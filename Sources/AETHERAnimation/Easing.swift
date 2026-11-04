import Foundation

public enum Easing {
    public static func linear(_ t: Double) -> Double { min(max(t, 0), 1) }
    public static func easeIn(_ t: Double) -> Double {
        let x = linear(t); return x * x
    }
    public static func easeOut(_ t: Double) -> Double {
        let x = linear(t); return 1 - (1 - x) * (1 - x)
    }
    public static func easeInOut(_ t: Double) -> Double {
        let x = linear(t)
        return x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2
    }
}
