import Foundation
import AETHERShared

public actor JSONPresetRepository: PresetRepository {
    private let directory: URL
    public init(directory: URL) { self.directory = directory }

    public func save(_ data: Data, id: PresetID) async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL(id), options: .atomic)
    }

    public func load(id: PresetID) async throws -> Data {
        try Data(contentsOf: fileURL(id))
    }

    public func list() async throws -> [PresetID] {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .map { PresetID(rawValue: $0.deletingPathExtension().lastPathComponent) }
    }

    public func delete(id: PresetID) async throws {
        let url = fileURL(id)
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }

    private func fileURL(_ id: PresetID) -> URL {
        // Sanitize IDs to prevent path traversal.
        let safe = id.rawValue.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "..", with: "_")
        return directory.appendingPathComponent(safe).appendingPathExtension("json")
    }
}
