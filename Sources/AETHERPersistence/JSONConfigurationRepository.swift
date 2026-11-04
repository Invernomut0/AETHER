import Foundation
import AETHERShared

public actor JSONConfigurationRepository: ConfigurationRepository {
    private let url: URL

    /// The stable per-user path used by the app composition root.
    public static var defaultURL: URL {
        URL.applicationSupportDirectory
            .appendingPathComponent("AETHER", isDirectory: true)
            .appendingPathComponent("configuration.json")
    }

    public init(url: URL) { self.url = url }

    /// Initializes a missing file and upgrades unversioned/v0 configurations atomically.
    /// Unsupported future schemas and invalid files are never overwritten.
    public func loadConfiguration() async throws -> AetherConfiguration {
        try Task.checkCancellation()
        guard FileManager.default.fileExists(atPath: url.path) else {
            try write(.default)
            return .default
        }
        let data = try Data(contentsOf: url)
        guard var object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AetherError.invalidState("Configuration must be a JSON object")
        }
        let version: Int
        if object["schemaVersion"] != nil {
            // Decode Int strictly: JSON booleans and fractional numbers are not schema versions.
            struct Header: Decodable { let schemaVersion: Int }
            version = try JSONDecoder().decode(Header.self, from: data).schemaVersion
        } else {
            version = 0
        }
        guard (0...AetherConfiguration.default.schemaVersion).contains(version) else {
            throw AetherError.unsupported("Unsupported configuration schema version: \(version)")
        }
        if version == 0 {
            let defaults = try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(AetherConfiguration.default)
            ) as? [String: Any] ?? [:]
            object = defaults.merging(object) { _, existing in existing }
            object["schemaVersion"] = AetherConfiguration.default.schemaVersion
        }
        let migratedData = try JSONSerialization.data(withJSONObject: object)
        let configuration = try JSONDecoder().decode(AetherConfiguration.self, from: migratedData)
        if version == 0 { try write(configuration) }
        return configuration
    }

    public func saveConfiguration(_ configuration: AetherConfiguration) async throws {
        guard configuration.schemaVersion == AetherConfiguration.default.schemaVersion else {
            throw AetherError.unsupported("Cannot save an unsupported configuration schema")
        }
        try write(configuration)
    }

    private func write(_ configuration: AetherConfiguration) throws {
        try Task.checkCancellation()
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(configuration)
        try data.write(to: url, options: .atomic)
    }
}
