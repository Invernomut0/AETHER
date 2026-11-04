import Foundation
import AETHERShared

public struct CaptureSessionID: Hashable, Sendable {
    public let rawValue: UUID
    public init(rawValue: UUID = UUID()) { self.rawValue = rawValue }
}

public struct CapturedFrameMetadata: Sendable {
    public let timestamp: Double
    public let width: Int
    public let height: Int
    public let isComplete: Bool

    public init(timestamp: Double, width: Int, height: Int, isComplete: Bool) {
        self.timestamp = timestamp
        self.width = width
        self.height = height
        self.isComplete = isComplete
    }
}

/// A copied, immutable complete frame; no CMSampleBuffer or CVPixelBuffer escapes its queue.
public struct CapturedFrame: Sendable {
    public let sessionID: CaptureSessionID
    public let metadata: CapturedFrameMetadata
    public let pixels: BGRAPixelFrame
    public let receivedAtUptime: TimeInterval
}

/// The caller must revalidate this M1 generation before and after asynchronous startup.
public struct CaptureRequest: Sendable {
    public let handle: RuntimeWindowHandle
    public let bundleIdentifier: String
    public let frame: CodableRect
    public let excludedBundleIDs: [String]

    public init(window: WindowDescriptor, excludedBundleIDs: [String]) throws {
        guard let handle = window.runtimeHandle, let bundle = window.bundleIdentifier, !bundle.isEmpty,
              let frame = window.frame, window.isOnScreen, !window.isMinimized else {
            throw AetherError.unsupported("Capture requires an on-screen, unambiguously registered native window")
        }
        self.handle = handle
        self.bundleIdentifier = bundle
        self.frame = frame
        self.excludedBundleIDs = excludedBundleIDs
    }
}

/// Deny known credential applications and configured application families, including helpers.
public enum CapturePrivacyPolicy {
    public static let credentialBundleIDs = [
        "com.1password", "com.agilebits.onepassword", "com.bitwarden.desktop",
        "org.keepassxc.keepassxc", "com.dashlane.dashlane", "com.lastpass.lastpass",
        "com.sinew.enpass", "in.sinew.enpass-desktop", "com.apple.keychainaccess",
        "com.apple.passwords", "com.apple.securityagent", "com.strongbox",
        "com.markmcguill.strongbox", "com.outercorner.secrets", "com.outercorner.secrets4"
    ]

    public static func allows(bundleIdentifier: String, excludedBundleIDs: [String]) -> Bool {
        let bundle = bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !bundle.isEmpty else { return false }
        return !(credentialBundleIDs + excludedBundleIDs).contains {
            let excluded = $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return !excluded.isEmpty && (bundle == excluded || bundle.hasPrefix(excluded + "."))
        }
    }
}
