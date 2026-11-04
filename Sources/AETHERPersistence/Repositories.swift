import Foundation
import AETHERShared

public protocol ConfigurationRepository: Sendable {
    func loadConfiguration() async throws -> AetherConfiguration
    func saveConfiguration(_ configuration: AetherConfiguration) async throws
}

public protocol PresetRepository: Sendable {
    func save(_ data: Data, id: PresetID) async throws
    func load(id: PresetID) async throws -> Data
    func list() async throws -> [PresetID]
    func delete(id: PresetID) async throws
}
