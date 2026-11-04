import Foundation
import Testing
import AETHERShared
import AETHERCore
import AETHERPersistence

struct CoordinatorTests {
    private func withCoordinator(
        _ body: (AetherCoordinator, URL) async throws -> Void
    ) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("configuration.json")
        let coordinator = AetherCoordinator(repository: JSONConfigurationRepository(url: url))
        try await body(coordinator, url)
    }

    @Test func startStopAndRestartAreIdempotent() async throws {
        try await withCoordinator { coordinator, _ in
            #expect(await coordinator.status() == false)
            try await coordinator.start()
            try await coordinator.start()
            #expect(await coordinator.status())
            #expect(await coordinator.currentConfiguration() == .default)
            await coordinator.stop()
            await coordinator.stop()
            #expect(await coordinator.status() == false)
            #expect(await coordinator.currentConfiguration() == nil)
            try await coordinator.start()
            #expect(await coordinator.status())
            await coordinator.stop()
        }
    }

    @Test func failedStartCanBeRetriedAfterRepair() async throws {
        try await withCoordinator { coordinator, url in
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            var configuration = AetherConfiguration.default
            configuration.schemaVersion = 2
            try JSONEncoder().encode(configuration).write(to: url)
            await #expect(throws: AetherError.unsupported("Unsupported configuration schema version: 2")) {
                try await coordinator.start()
            }
            #expect(await coordinator.status() == false)
            #expect(await coordinator.currentConfiguration() == nil)
            try JSONEncoder().encode(AetherConfiguration.default).write(to: url)
            try await coordinator.start()
            #expect(await coordinator.status())
            await coordinator.stop()
        }
    }

    @Test func cancelledStartDoesNotCreateConfiguration() async throws {
        try await withCoordinator { coordinator, url in
            let task = Task {
                withUnsafeCurrentTask { $0?.cancel() }
                try await coordinator.start()
            }
            await #expect(throws: CancellationError.self) { try await task.value }
            #expect(await coordinator.status() == false)
            #expect(FileManager.default.fileExists(atPath: url.path) == false)
        }
    }

    @Test @MainActor func permissionChecksMatchPassiveSystemState() async {
        let permissions = PermissionCoordinator()
        #expect(await permissions.accessibilityGranted() == permissions.accessibilityTrusted())
        let recordingGranted = await permissions.screenRecordingGranted()
        let captureStatus = await permissions.screenCaptureStatus()
        #expect(recordingGranted == captureStatus)
    }
}