import Foundation

public enum QualityPreset: String, Codable, Sendable {
    case auto, low, balanced, high, ultra
}

public struct AetherConfiguration: Codable, Sendable, Equatable {
    public var schemaVersion: Int
    public var launchAtLogin: Bool
    public var effectsEnabled: Bool
    public var quality: QualityPreset
    public var reduceMotion: Bool
    public var captureExcludedBundleIDs: [String]
    public var globalHotkeysEnabled: Bool

    public init(schemaVersion: Int, launchAtLogin: Bool, effectsEnabled: Bool,
                quality: QualityPreset, reduceMotion: Bool,
                captureExcludedBundleIDs: [String], globalHotkeysEnabled: Bool) {
        self.schemaVersion = schemaVersion
        self.launchAtLogin = launchAtLogin
        self.effectsEnabled = effectsEnabled
        self.quality = quality
        self.reduceMotion = reduceMotion
        self.captureExcludedBundleIDs = captureExcludedBundleIDs
        self.globalHotkeysEnabled = globalHotkeysEnabled
    }

    public static let `default` = AetherConfiguration(
        schemaVersion: 1,
        launchAtLogin: false,
        effectsEnabled: true,
        quality: .auto,
        reduceMotion: false,
        captureExcludedBundleIDs: [],
        globalHotkeysEnabled: true
    )
}
