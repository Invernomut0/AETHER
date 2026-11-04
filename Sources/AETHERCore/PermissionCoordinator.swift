import Foundation
import ApplicationServices
import CoreGraphics

/// Permission inspection is passive; only explicit request methods may prompt.
@MainActor
public final class PermissionCoordinator: PermissionChecking {
    public init() {}

    public func accessibilityTrusted(prompt: Bool = false) -> Bool {
        if prompt { AetherLog.permissions.info("Accessibility permission requested by user") }
        // Public AX option key, verified against the SDK constant. Its C declaration
        // is mutable, so referencing that global directly violates Swift 6 isolation.
        let options = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    public func accessibilityGranted() async -> Bool {
        accessibilityTrusted()
    }

    public func screenRecordingGranted() async -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    public func screenCaptureStatus() async -> Bool {
        await screenRecordingGranted()
    }

    public func requestScreenCaptureAccess() -> Bool {
        AetherLog.permissions.info("Screen Recording permission requested by user")
        return CGRequestScreenCaptureAccess()
    }
}
