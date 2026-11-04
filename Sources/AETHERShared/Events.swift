import Foundation

public enum AetherEvent: Sendable {
    case windowDiscovered(WindowID)
    case windowRemoved(WindowID)
    case windowGeometryChanged(WindowID, CodableRect)
    case windowFocused(WindowID)
    case displayTopologyChanged
    case effectStarted(AnimationID)
    case effectCompleted(AnimationID)
    case effectFailed(AnimationID, String)
    case permissionChanged(String, Bool)
    case renderingDegraded(String)
    case systemResourcePressure
}
