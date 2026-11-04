import Foundation
import Testing
import AETHERShared
import AETHERPersistence

/// Uses the shipped configuration and real filesystem I/O; no service mocks.
struct ConfigurationRepositoryTests {
    private func withRepository(
        _ body: (JSONConfigurationRepository, URL) async throws -> Void
    ) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("configuration.json")
        try await body(JSONConfigurationRepository(url: url), url)
    }

    private func shippedData() throws -> Data {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try Data(contentsOf: root.appendingPathComponent("Configuration/DefaultConfiguration.json"))
    }

    @Test func missingFilePersistsDefaults() async throws {
        try await withRepository { repository, url in
            let loaded = try await repository.loadConfiguration()
            #expect(loaded == .default)
            #expect(try JSONDecoder().decode(AetherConfiguration.self, from: Data(contentsOf: url)) == .default)
        }
    }

    @Test func shippedConfigurationRoundTrips() async throws {
        try await withRepository { repository, url in
            let data = try shippedData()
            try data.write(to: url)
            let loaded = try await repository.loadConfiguration()
            #expect(loaded == .default)
            var edited = loaded
            edited.reduceMotion = true
            edited.quality = .balanced
            try await repository.saveConfiguration(edited)
            #expect(try await repository.loadConfiguration() == edited)
        }
    }

    @Test(arguments: [true, false]) func legacyConfigurationMigrates(presentVersion: Bool) async throws {
        try await withRepository { repository, url in
            var object = try #require(JSONSerialization.jsonObject(with: shippedData()) as? [String: Any])
            object["schemaVersion"] = presentVersion ? 0 : nil
            object.removeValue(forKey: "globalHotkeysEnabled")
            object["reduceMotion"] = true
            try JSONSerialization.data(withJSONObject: object).write(to: url)
            let loaded = try await repository.loadConfiguration()
            #expect(loaded.schemaVersion == 1)
            #expect(loaded.reduceMotion)
            #expect(loaded.globalHotkeysEnabled == AetherConfiguration.default.globalHotkeysEnabled)
            #expect(try JSONDecoder().decode(AetherConfiguration.self, from: Data(contentsOf: url)) == loaded)
        }
    }

    @Test(arguments: [-1, 2]) func unsupportedSchemasRemainUntouched(version: Int) async throws {
        try await withRepository { repository, url in
            var object = try #require(JSONSerialization.jsonObject(with: shippedData()) as? [String: Any])
            object["schemaVersion"] = version
            let data = try JSONSerialization.data(withJSONObject: object)
            try data.write(to: url)
            await #expect(throws: AetherError.unsupported("Unsupported configuration schema version: \(version)")) {
                try await repository.loadConfiguration()
            }
            #expect(try Data(contentsOf: url) == data)
        }
    }

    @Test func invalidConfigurationRemainsUntouched() async throws {
        try await withRepository { repository, url in
            var object = try #require(JSONSerialization.jsonObject(with: shippedData()) as? [String: Any])
            object["quality"] = "unsupported-quality"
            let data = try JSONSerialization.data(withJSONObject: object)
            try data.write(to: url)
            await #expect(throws: DecodingError.self) { try await repository.loadConfiguration() }
            #expect(try Data(contentsOf: url) == data)
        }
    }

    @Test func unsupportedSaveDoesNotOverwrite() async throws {
        try await withRepository { repository, url in
            let data = try shippedData()
            try data.write(to: url)
            var configuration = AetherConfiguration.default
            configuration.schemaVersion = 2
            await #expect(throws: AetherError.unsupported("Cannot save an unsupported configuration schema")) {
                try await repository.saveConfiguration(configuration)
            }
            #expect(try Data(contentsOf: url) == data)
        }
    }

    @Test(arguments: ["[", "[]", "{\"schemaVersion\":true}", "{\"schemaVersion\":1.5}"])
    func malformedConfigurationRemainsUntouched(json: String) async throws {
        try await withRepository { repository, url in
            let data = Data(json.utf8)
            try data.write(to: url)
            await #expect(throws: (any Error).self) { try await repository.loadConfiguration() }
            #expect(try Data(contentsOf: url) == data)
        }
    }

    @Test func cancelledLoadDoesNotModifyFile() async throws {
        try await withRepository { repository, url in
            let data = try shippedData()
            try data.write(to: url)
            let task = Task {
                withUnsafeCurrentTask { $0?.cancel() }
                return try await repository.loadConfiguration()
            }
            await #expect(throws: CancellationError.self) { try await task.value }
            #expect(try Data(contentsOf: url) == data)
        }
    }

    @Test func currentSchemaDoesNotSilentlyFillMissingFields() async throws {
        try await withRepository { repository, url in
            var object = try #require(JSONSerialization.jsonObject(with: shippedData()) as? [String: Any])
            object.removeValue(forKey: "quality")
            let data = try JSONSerialization.data(withJSONObject: object)
            try data.write(to: url)
            await #expect(throws: DecodingError.self) { try await repository.loadConfiguration() }
            #expect(try Data(contentsOf: url) == data)
        }
    }
}