import Foundation
import AETHERShared
import AETHERPersistence

/// Owns bootstrap state. Native services are connected only as their milestone gates pass.
public actor AetherCoordinator {
    public let eventBus: EventBus
    private let repository: any ConfigurationRepository
    private var isRunning = false
    private var startID: UUID?
    private var configuration: AetherConfiguration?

    public init(eventBus: EventBus = EventBus(),
                repository: any ConfigurationRepository = JSONConfigurationRepository(
                    url: JSONConfigurationRepository.defaultURL
                )) {
        self.eventBus = eventBus
        self.repository = repository
    }

    /// Loads configuration before publishing readiness; cancellation leaves no running bootstrap.
    public func start() async throws {
        try Task.checkCancellation()
        guard !isRunning else { return }
        guard startID == nil else {
            throw AetherError.invalidState("Bootstrap is already in progress")
        }
        let id = UUID()
        startID = id
        AetherLog.lifecycle.info("Bootstrap started")
        do {
            let loaded = try await repository.loadConfiguration()
            try Task.checkCancellation()
            guard startID == id else { throw AetherError.cancelled }
            configuration = loaded
            isRunning = true
            startID = nil
            AetherLog.configuration.info("Configuration loaded; schema \(loaded.schemaVersion)")
            AetherLog.lifecycle.info("Bootstrap ready; capture and rendering remain disconnected")
        } catch {
            if startID == id {
                startID = nil
                configuration = nil
                isRunning = false
            }
            AetherLog.lifecycle.error("Bootstrap failed or cancelled")
            throw error
        }
    }

    /// Invalidates an in-flight start and clears the loaded configuration. Safe to repeat.
    public func stop() async {
        startID = nil
        isRunning = false
        configuration = nil
        AetherLog.lifecycle.info("Bootstrap stopped")
    }

    public func status() -> Bool { isRunning }

    public func currentConfiguration() -> AetherConfiguration? { configuration }
}
