import AppKit
import Foundation
import Observation

/// File metadata, not a signature check or proof that Kinetiq's event tap is ready.
public struct KinetiqApplicationMetadata: Equatable, Sendable {
    public let applicationURL: URL
    public let executableURL: URL
    public let version: String
    public let build: String
}

public enum KinetiqEngineError: Error, LocalizedError, Equatable, Sendable {
    case consentRequired
    case invalidApplication(String)
    case conflictingApplication
    case operationInProgress
    case launchFailed(String)
    case launchTimedOut
    case identityMismatch
    case terminationRefused
    case terminationTimedOut

    public var errorDescription: String? {
        switch self {
        case .consentRequired:
            "Explicit experimental consent is required before starting or connecting to Kinetiq."
        case .invalidApplication(let reason):
            "Invalid Kinetiq application: \(reason)"
        case .conflictingApplication:
            "Another Kinetiq installation or multiple instances are running. Quit them from their wave menus before connecting."
        case .operationInProgress:
            "A Kinetiq operation or unresolved launch is already in progress. Refresh status; do not relaunch blindly."
        case .launchFailed(let reason):
            "Launch Services could not confirm the launch: \(reason). Refresh and inspect Kinetiq's wave menu."
        case .launchTimedOut:
            "Launch confirmation exceeded 10 seconds. The request cannot be revoked; Kinetiq may still appear. Refresh, then use Stop Kinetiq."
        case .identityMismatch:
            "The running application's bundle or executable does not match the selected installation. No termination was sent."
        case .terminationRefused:
            "The normal quit request was not accepted. The process handle is retained; retry Stop or use Quit Kinetiq in its wave menu."
        case .terminationTimedOut:
            "Kinetiq has not exited within 10 seconds. No forced termination was used. Retry Stop or use its wave menu; window restoration is unverified."
        }
    }
}

/// Explicit opt-in launcher for a separately installed GPL application; no linked Kinetiq code or IPC.
/// All ownership and AppKit calls stay on MainActor. Process existence never certifies effect readiness.
@MainActor
@Observable
public final class KinetiqEngineCoordinator {
    public static let shared = KinetiqEngineCoordinator()
    public nonisolated static let bundleIdentifier = "io.github.invernomut0.Kinetiq"

    public private(set) var metadata: KinetiqApplicationMetadata?
    public private(set) var processID: Int32?
    public private(set) var isStarting = false
    public private(set) var isStopping = false
    public private(set) var externalProcessCount = 0
    public private(set) var lastError: String?
    public private(set) var statusMessage = "Not connected. Kinetiq is never started automatically."
    private var application: NSRunningApplication?
    private var pendingLaunchID: UUID?
    private var launchResult: Result<Void, KinetiqEngineError>?

    public var isLaunchPending: Bool { pendingLaunchID != nil }
    public var isRunning: Bool { application.map { !$0.isTerminated } ?? false }

    /// Conservative interlock, including manually launched instances and unresolved OS callbacks.
    /// Call refreshStatus for observable UI updates; command admission also checks the live inventory.
    public var isActive: Bool {
        isStarting || isStopping || isLaunchPending || isRunning || !Self.runningApplications.isEmpty
    }

    public init() {}

    /// Suggestions only: discovering or validating a bundle never launches it or requests permissions.
    public nonisolated static var applicationCandidates: [URL] {
        var developmentRoot = URL(fileURLWithPath: #filePath)
        for _ in 0..<4 { developmentRoot.deleteLastPathComponent() }
        return [
            developmentRoot.appendingPathComponent("Wobbly/build/Kinetiq.app", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications/Kinetiq.app", isDirectory: true),
            URL(fileURLWithPath: "/Applications/Kinetiq.app", isDirectory: true)
        ]
    }

    /// Reads the actual Info.plist and required bundle resources without loading executable code.
    /// Identity fields are not an authenticity guarantee: only select a trusted local build.
    public nonisolated static func validateApplication(at url: URL) throws -> KinetiqApplicationMetadata {
        guard url.isFileURL else { throw KinetiqEngineError.invalidApplication("select a local .app bundle") }
        let canonical = url.standardizedFileURL.resolvingSymlinksInPath()
        let files = FileManager.default
        guard canonical.pathExtension.lowercased() == "app",
              (try? canonical.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else {
            throw KinetiqEngineError.invalidApplication("the .app directory does not exist")
        }
        let infoURL = canonical.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: infoURL),
              let info = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any],
              info["CFBundleIdentifier"] as? String == bundleIdentifier,
              info["CFBundleExecutable"] as? String == "Kinetiq",
              info["CFBundlePackageType"] as? String == "APPL",
              let version = info["CFBundleShortVersionString"] as? String,
              !version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let build = info["CFBundleVersion"] as? String,
              !build.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw KinetiqEngineError.invalidApplication("bundle identifier, executable or version metadata does not match Kinetiq")
        }
        let executable = canonical.appendingPathComponent("Contents/MacOS/Kinetiq").resolvingSymlinksInPath()
        guard executable.path.hasPrefix(canonical.path + "/"),
              (try? executable.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true,
              files.isExecutableFile(atPath: executable.path) else {
            throw KinetiqEngineError.invalidApplication("the executable is missing, outside the bundle or not executable")
        }
        let resources = canonical.appendingPathComponent("Contents/Resources", isDirectory: true).resolvingSymlinksInPath()
        let effects = resources.appendingPathComponent("Kinetiq_KinetiqEffects.bundle", isDirectory: true).resolvingSymlinksInPath()
        guard resources.path.hasPrefix(canonical.path + "/"), effects.path.hasPrefix(resources.path + "/"),
              (try? effects.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true,
              let entries = try? files.contentsOfDirectory(at: effects, includingPropertiesForKeys: nil),
              !entries.isEmpty else {
            throw KinetiqEngineError.invalidApplication("the packaged Kinetiq effects resources are missing or empty; rebuild the app bundle")
        }
        return KinetiqApplicationMetadata(applicationURL: canonical, executableURL: executable, version: version, build: build)
    }

    /// Passive refresh does not acquire control of an independently running process.
    public func refreshStatus() {
        externalProcessCount = Self.runningApplications.count
        if let application, application.isTerminated {
            self.application = nil
            processID = nil
            statusMessage = "Process exited. Native window restoration has not been independently verified."
        } else if let application {
            processID = application.processIdentifier
        } else if !isStarting, !isStopping, !isLaunchPending, externalProcessCount > 0 {
            statusMessage = "Kinetiq is already running independently. Explicit consent and Start / Connect are required to manage it here."
        } else if !isStarting, !isStopping, !isLaunchPending, externalProcessCount == 0, processID == nil {
            statusMessage = "No Kinetiq process detected. Window restoration is not certified by process status."
        }
    }

    /// Start also explicitly authorizes connection to one existing instance at the exact selected URL.
    /// Cancellation/timeout ends this wait only. A late callback still retains the actual app handle.
    public func start(applicationURL: URL, experimentalConsent: Bool) async throws {
        try Task.checkCancellation()
        guard experimentalConsent else { throw KinetiqEngineError.consentRequired }
        guard !isStarting, !isStopping, !isLaunchPending else { throw KinetiqEngineError.operationInProgress }
        isStarting = true
        lastError = nil
        defer { isStarting = false }
        do {
            let selected = try Self.validateApplication(at: applicationURL)
            refreshStatus()
            if let application, !application.isTerminated {
                guard Self.matches(application, selected) else { throw KinetiqEngineError.conflictingApplication }
                guard Self.runningApplications.count == 1 else { throw KinetiqEngineError.conflictingApplication }
                return
            }
            let existing = Self.runningApplications
            guard existing.count <= 1, existing.allSatisfy({ Self.matches($0, selected) }) else {
                throw KinetiqEngineError.conflictingApplication
            }
            metadata = selected
            try Task.checkCancellation()
            if let existing = existing.first {
                retain(existing, metadata: selected)
                statusMessage = "Connected to an already-running process; not launched by AETHER. Effect readiness is unknown."
                return
            }
            let token = UUID()
            pendingLaunchID = token
            launchResult = nil
            statusMessage = "Requesting Kinetiq launch. Kinetiq may ask for its own macOS permissions."
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.createsNewApplicationInstance = false
            configuration.allowsRunningApplicationSubstitution = false
            configuration.activates = false
            configuration.addsToRecentItems = false
            // Intentionally retained by the OS callback even if the caller stops awaiting.
            // NSRunningApplication is SDK-Sendable; mutations are handed back to MainActor.
            NSWorkspace.shared.openApplication(at: selected.applicationURL, configuration: configuration) { [self] app, error in
                let message = error?.localizedDescription
                Task { @MainActor in
                    self.finishLaunch(token: token, selected: selected, application: app, errorMessage: message)
                }
            }
            let clock = ContinuousClock()
            let deadline = clock.now.advanced(by: .seconds(10))
            while pendingLaunchID == token {
                try Task.checkCancellation()
                guard clock.now < deadline else { throw KinetiqEngineError.launchTimedOut }
                try await clock.sleep(for: .milliseconds(100))
            }
            try Task.checkCancellation()
            guard let launchResult else { throw KinetiqEngineError.launchFailed("no completion result") }
            try launchResult.get()
            refreshStatus()
            guard isRunning else { throw KinetiqEngineError.launchFailed("the process exited before launch confirmation") }
        } catch {
            if error is CancellationError {
                statusMessage = "Launch wait cancelled. An issued OS request is not revoked; refresh and use Stop Kinetiq if it appears."
            }
            lastError = error is CancellationError ? statusMessage : error.localizedDescription
            throw error
        }
    }

    /// Sends only a normal quit request and waits at most ten seconds. No SIGKILL/forced fallback.
    /// Failures and cancellation retain the instance reference so a later Stop can retry safely.
    public func stop() async throws {
        try Task.checkCancellation()
        guard !isStarting, !isStopping else { throw KinetiqEngineError.operationInProgress }
        isStopping = true
        lastError = nil
        defer { isStopping = false }
        do {
            let clock = ContinuousClock()
            let deadline = clock.now.advanced(by: .seconds(10))
            statusMessage = "Waiting for normal Kinetiq exit; window restoration is not independently verified."
            while isLaunchPending {
                try Task.checkCancellation()
                guard clock.now < deadline else { throw KinetiqEngineError.launchTimedOut }
                try await clock.sleep(for: .milliseconds(100))
            }
            refreshStatus()
            guard let application else {
                guard Self.runningApplications.isEmpty else { throw KinetiqEngineError.identityMismatch }
                return
            }
            guard let metadata, Self.matches(application, metadata) else { throw KinetiqEngineError.identityMismatch }
            try Task.checkCancellation()
            guard application.terminate() || application.isTerminated else { throw KinetiqEngineError.terminationRefused }
            while !application.isTerminated {
                try Task.checkCancellation()
                guard clock.now < deadline else { throw KinetiqEngineError.terminationTimedOut }
                try await clock.sleep(for: .milliseconds(100))
            }
            refreshStatus()
            lastError = nil
        } catch {
            lastError = error is CancellationError
                ? "Quit wait cancelled; a normal quit request may still complete. The process handle is retained. Refresh or retry Stop."
                : error.localizedDescription
            throw error
        }
    }

    private static var runningApplications: [NSRunningApplication] {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).filter { !$0.isTerminated }
    }

    private static func matches(_ app: NSRunningApplication, _ selected: KinetiqApplicationMetadata) -> Bool {
        !app.isTerminated && app.bundleIdentifier == bundleIdentifier
            && app.bundleURL?.standardizedFileURL.resolvingSymlinksInPath() == selected.applicationURL
            && app.executableURL?.standardizedFileURL.resolvingSymlinksInPath() == selected.executableURL
    }

    private func retain(_ app: NSRunningApplication, metadata: KinetiqApplicationMetadata) {
        application = app
        self.metadata = metadata
        processID = app.processIdentifier
        externalProcessCount = Self.runningApplications.count
    }

    private func finishLaunch(token: UUID, selected: KinetiqApplicationMetadata,
                              application app: NSRunningApplication?, errorMessage: String?) {
        guard pendingLaunchID == token else { return }
        let late = !isStarting
        pendingLaunchID = nil
        let candidates = Self.runningApplications.filter { Self.matches($0, selected) }
        let resolved = app ?? (candidates.count == 1 ? candidates.first : nil)
        if let resolved, Self.matches(resolved, selected) {
            retain(resolved, metadata: selected)
            statusMessage = "Process running · effect readiness unknown."
            if late {
                statusMessage += " Launch completed after the wait ended; use Stop Kinetiq to quit."
            }
            if let errorMessage {
                let failure = KinetiqEngineError.launchFailed(errorMessage)
                launchResult = .failure(failure)
                lastError = failure.localizedDescription
            } else {
                launchResult = .success(())
            }
        } else {
            let failure: KinetiqEngineError = app == nil
                ? .launchFailed(errorMessage ?? "no matching running process returned") : .identityMismatch
            launchResult = .failure(failure)
            lastError = failure.localizedDescription
            statusMessage = "Launch not confirmed. Inspect the wave menu and refresh before retrying."
        }
    }
}