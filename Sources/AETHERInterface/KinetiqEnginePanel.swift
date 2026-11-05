import AppKit
import SwiftUI
import UniformTypeIdentifiers
import AETHERCore

/// A native control surface for the real, independent Kinetiq app, not an AETHER preview.
@MainActor
public struct KinetiqEnginePanel: View {
    private let runtime: AetherRuntimeModel
    @State private var engine = KinetiqEngineCoordinator.shared
    @State private var selectedURL: URL?
    @State private var consent = false
    @State private var selectionError: String?
    @State private var request: Request?
    @State private var requestID = UUID()

    private enum Request { case start, stop }

    public init(runtime: AetherRuntimeModel) {
        self.runtime = runtime
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("KINETIQ · EXTERNAL ENGINE", systemImage: "water.waves")
                        .font(.caption.monospaced().weight(.semibold)).foregroundStyle(.teal)
                    Text("Real desktop effects. Explicit control.").font(.title2.bold())
                    Text("A separately installed GPL application, running in its own process. No Kinetiq code is linked into AETHER.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Refresh", systemImage: "arrow.clockwise") { engine.refreshStatus() }
            }

            GroupBox("Experimental · read before enabling") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Private APIs and real native-window changes", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange).font(.headline)
                    Text("Kinetiq uses private AX window mapping, global event taps, click replay and temporary off-screen window parking. macOS updates can break it. Save work and test only disposable windows first; crashes or failed cleanup can leave windows displaced. Restoration is not guaranteed.")
                    Text("Kinetiq requests its own Accessibility and Screen Recording access on explicit launch. Grants to AETHER do not grant access to Kinetiq. Follow Kinetiq's prompts in System Settings; restart Kinetiq if required. System recording indicators may appear or persist: their absence is not guaranteed.")
                    Text("Kinetiq continues running if AETHER quits or this page closes. Use Stop Kinetiq here, or the wave icon → Quit Kinetiq. Stop requests a normal quit only; AETHER never force-quits it.")
                    Toggle("I accept these experimental risks and authorize starting or connecting to this Kinetiq installation.", isOn: $consent)
                        .toggleStyle(.checkbox)
                        .disabled(engine.isStarting || engine.isStopping || engine.isLaunchPending)
                }
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
            }

            GroupBox("Application") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(selectedURL?.path ?? "Choose a trusted Kinetiq.app installation.")
                        .font(.caption.monospaced()).textSelection(.enabled)
                    HStack {
                        Button("Choose Kinetiq.app…", systemImage: "folder") { chooseApplication() }
                            .disabled(engine.isStarting || engine.isStopping || engine.isLaunchPending || engine.isRunning)
                        if let selectedURL, let info = try? KinetiqEngineCoordinator.validateApplication(at: selectedURL) {
                            Text("Version \(info.version) · build \(info.build)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Text("Build the real bundle with bash Scripts/build-kinetiq.sh [sourcecheckout] (default: sibling Wobbly), then select its build/Kinetiq.app. Installed copies in ~/Applications and /Applications are also discovered. Metadata validation does not authenticate a build.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(6)
            }

            HStack(spacing: 12) {
                Button("Start / Connect Kinetiq", systemImage: "play.fill") {
                    runtime.removePreviewOverlay()
                    submit(.start)
                }
                .buttonStyle(.borderedProminent).tint(.teal)
                .disabled(!consent || selectedURL == nil || engine.isStarting || engine.isStopping
                          || engine.isLaunchPending || engine.isRunning || runtime.isWindowOperationRunning || runtime.isPreviewRunning)
                Button("Stop Kinetiq", systemImage: "stop.fill") { submit(.stop) }
                    .disabled(engine.isStarting || engine.isStopping || (!engine.isRunning && !engine.isLaunchPending))
                if engine.isStarting || engine.isStopping {
                    Button("Cancel wait") { request = nil; requestID = UUID() }
                    ProgressView().controlSize(.small)
                }
            }
            if runtime.isWindowOperationRunning || runtime.isPreviewRunning {
                Text("Finish or cancel AETHER's current window operation before starting Kinetiq.")
                    .font(.caption).foregroundStyle(.orange)
            }
            Label(engine.isRunning ? "Process running · readiness unknown" : (engine.isLaunchPending ? "Launch outcome pending" : "Not connected"),
                  systemImage: engine.isRunning ? "waveform" : "circle.dashed")
                .font(.headline)
            if let processID = engine.processID {
                Text("PID \(processID) · \(engine.metadata?.version ?? "unknown version")")
                    .font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            Text(engine.statusMessage).font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
            if let error = selectionError ?? engine.lastError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange).textSelection(.enabled)
            }

            GroupBox("Configure and verify in Kinetiq") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Open Kinetiq's wave icon in the macOS menu bar. Confirm Kinetiq Enabled and Drag from Title Bar; title-bar dragging is enabled by default, but saved settings may differ.")
                    Text("2. Open Setup… and choose the Close effect you want, for example Fire. Do not assume a fresh install has a close effect selected. Physics, exclusions and effect choices belong to Kinetiq, not to an AETHER fallback.")
                    Text("3. Open AETHER Test Lab manually. Drag a disposable window by its title bar, then close only an empty disposable window. Inspect the original window position, input, overlays and macOS indicators before and after Stop.")
                    Text("Process status cannot verify Kinetiq's permissions, event tap, shaders or effects. There is no readiness IPC. This page does not inject clicks, close documents or run synthetic effects.")
                        .foregroundStyle(.secondary)
                }
                .font(.callout).frame(maxWidth: .infinity, alignment: .leading).padding(6)
            }
        }
        .task {
            engine.refreshStatus()
            if selectedURL == nil {
                selectedURL = engine.metadata?.applicationURL ?? KinetiqEngineCoordinator.applicationCandidates.first {
                    (try? KinetiqEngineCoordinator.validateApplication(at: $0)) != nil
                }
            }
            while !Task.isCancelled {
                engine.refreshStatus()
                do { try await Task.sleep(for: .milliseconds(500)) }
                catch { return }
            }
        }
        .task(id: requestID) {
            guard let request else { return }
            // Consume each explicit button press once, including across disappearance/reappearance.
            self.request = nil
            do {
                switch request {
                case .start:
                    guard !runtime.isWindowOperationRunning, !runtime.isPreviewRunning, let selectedURL else { return }
                    try await engine.start(applicationURL: selectedURL, experimentalConsent: consent)
                case .stop:
                    try await engine.stop()
                }
            } catch {
                // Coordinator retains uncertain process ownership and publishes actionable diagnostics.
                selectionError = error is CancellationError ? nil : error.localizedDescription
            }
        }
    }

    private func submit(_ request: Request) {
        selectionError = nil
        self.request = request
        requestID = UUID()
    }

    /// Only file selection: choosing a bundle never launches or changes another application's state.
    private func chooseApplication() {
        let panel = NSOpenPanel()
        panel.title = "Choose the real Kinetiq application"
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = selectedURL?.deletingLastPathComponent()
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            selectedURL = try KinetiqEngineCoordinator.validateApplication(at: url).applicationURL
            consent = false
            selectionError = nil
        } catch {
            selectionError = error.localizedDescription
        }
    }
}