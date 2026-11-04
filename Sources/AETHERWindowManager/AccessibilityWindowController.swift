import Foundation
import AppKit
import ApplicationServices
import AETHERShared

@MainActor
public final class AccessibilityWindowController: WindowControlling {
    public init() {}

    public func setFrame(_ frame: CGRect, for window: RuntimeWindowHandle) async throws {
        guard AXIsProcessTrusted() else {
            throw AetherError.permissionDenied("Accessibility permission is required")
        }
        let appElement = AXUIElementCreateApplication(pid_t(window.processID))
        var windowsRef: CFTypeRef?
        let windowsError = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        guard windowsError == .success,
              let windows = windowsRef as? [AXUIElement],
              let target = windows.first else {
            throw AetherError.notFound("Could not resolve an Accessibility window element. A production implementation must correlate the AX element to the target CGWindowID.")
        }

        var position = CGPoint(x: frame.origin.x, y: frame.origin.y)
        var size = CGSize(width: frame.width, height: frame.height)
        guard let positionValue = AXValueCreate(.cgPoint, &position),
              let sizeValue = AXValueCreate(.cgSize, &size) else {
            throw AetherError.operationFailed("Could not create AX geometry values")
        }

        let positionResult = AXUIElementSetAttributeValue(target, kAXPositionAttribute as CFString, positionValue)
        let sizeResult = AXUIElementSetAttributeValue(target, kAXSizeAttribute as CFString, sizeValue)
        guard positionResult == .success, sizeResult == .success else {
            throw AetherError.unsupported("The selected application window did not accept the requested geometry")
        }
    }

    public func activate(_ window: RuntimeWindowHandle) async throws {
        let app = NSRunningApplication(processIdentifier: pid_t(window.processID))
        guard app?.activate(options: []) == true else {
            throw AetherError.operationFailed("Application activation failed")
        }
    }
}
