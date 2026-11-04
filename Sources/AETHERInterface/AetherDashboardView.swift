import SwiftUI
import AETHERShared

public struct AetherDashboardView: View {
    private let runtime: AetherRuntimeModel
    @State private var selectedSection = "Overview"
    private let sections = ["Overview", "Windows", "Effects", "Animation Studio", "Physics", "Layouts", "Workspaces", "Rules", "Performance", "Diagnostics", "Settings"]

    public init(runtime: AetherRuntimeModel = AetherRuntimeModel()) {
        self.runtime = runtime
    }

    public var body: some View {
        NavigationSplitView {
            List(sections, id: \.self, selection: $selectedSection) { section in
                Label(section, systemImage: icon(for: section))
                    .tag(section)
            }
            .navigationTitle("AETHER")
            .frame(minWidth: 190)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(selectedSection).font(.largeTitle.bold())
                    if selectedSection == "Overview" {
                        overview
                    } else if selectedSection == "Windows" {
                        NativeWindowsPanel(runtime: runtime)
                    } else {
                        ContentUnavailableView(
                            selectedSection,
                            systemImage: icon(for: selectedSection),
                            description: Text("This workspace is scaffolded. Implement its milestone-specific workflow and connect it to live services.")
                        )
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minWidth: 600, minHeight: 420)
        }
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 16) {
            if runtime.isStarting {
                ProgressView("Loading configuration…")
            }
            if let error = runtime.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
                Button("Retry startup") { Task { await runtime.start() } }
            }
            HStack(spacing: 12) {
                statusCard("Bootstrap", value: runtime.isRunning ? "Ready · M0" : "Stopped", symbol: "power")
                statusCard("Accessibility", value: runtime.accessibilityGranted ? "Granted" : "Not granted", symbol: "accessibility")
                statusCard("Screen Recording", value: runtime.screenRecordingGranted ? "Granted" : "Not granted", symbol: "lock.shield")
            }
            Text("Welcome to AETHER").font(.title2.bold())
            Text("Bootstrap loads your versioned configuration. Open Windows for native control and an explicit, five-second captured Metal preview. Startup never starts capture. Preview requires Screen Recording consent; physical display and recovery checks remain manual.")
                .foregroundStyle(.secondary)
            if let version = runtime.schemaVersion {
                Text("Configuration schema: \(version)").font(.caption)
            }
            HStack {
                Button("Request Accessibility") { Task { await runtime.requestAccessibility() } }
                Button("Request Screen Recording") { Task { await runtime.requestScreenRecording() } }
                Button("Refresh permissions") { Task { await runtime.refreshPermissions() } }
            }
            Text("Permissions are requested only when you press the corresponding button. After changing access in System Settings, refresh or relaunch AETHER.")
                .font(.caption).foregroundStyle(.secondary)
            Label("Native window state remains authoritative.", systemImage: "checkmark.shield")
            Label("Effects use temporary overlays and always require cleanup.", systemImage: "rectangle.on.rectangle")
        }
    }

    private func statusCard(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol).font(.title2)
            Text(title).font(.headline)
            Text(value).foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func icon(for section: String) -> String {
        switch section {
        case "Overview": "square.grid.2x2"
        case "Windows": "macwindow.on.rectangle"
        case "Effects": "sparkles"
        case "Animation Studio": "timeline.selection"
        case "Physics": "atom"
        case "Layouts": "rectangle.split.2x2"
        case "Workspaces": "square.3.layers.3d"
        case "Rules": "arrow.triangle.branch"
        case "Performance": "gauge"
        case "Diagnostics": "stethoscope"
        default: "gearshape"
        }
    }
}
