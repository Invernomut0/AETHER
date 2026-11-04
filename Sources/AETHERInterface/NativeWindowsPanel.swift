import SwiftUI
import AppKit
import AETHERShared
import AETHERWindowManager

enum WindowPanelCommand {
    case refresh
    case focus(RuntimeWindowHandle)
    case setFrame(RuntimeWindowHandle, CodableRect)
    case preview(RuntimeWindowHandle)
}

/// Native instrument-panel styling: compact capability labels and explicit, guarded commands.
struct NativeWindowsPanel: View {
    let runtime: AetherRuntimeModel
    @State private var requestID = UUID()
    @State private var command: WindowPanelCommand = .refresh
    @State private var search = ""
    @State private var showReadOnly = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NATIVE WINDOWS").font(.caption.monospaced().weight(.semibold)).foregroundStyle(.teal)
                    Text("One window. One verified target.").font(.title2.bold())
                }
                Spacer()
                Button("Refresh", systemImage: "arrow.clockwise") { submit(.refresh) }
                    .disabled(runtime.isWindowOperationRunning)
                if runtime.isPreviewRunning {
                    Button("Stop preview", systemImage: "stop.fill") {
                        runtime.removePreviewOverlay()
                        submit(.refresh)
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            Text("Native control needs Accessibility only. Preview captures just the selected window for up to five seconds and requires explicit Screen Recording consent. It never replaces, hides or moves the original. Moving or resizing ends the preview.")
                .font(.callout).foregroundStyle(.secondary)
            if !runtime.screenRecordingGranted {
                Label("Preview unavailable: grant Screen Recording in Overview, then restart if macOS requests it.", systemImage: "lock.shield")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                TextField("Filter application or window title", text: $search)
                    .textFieldStyle(.roundedBorder)
                Toggle("Include read-only", isOn: $showReadOnly).toggleStyle(.checkbox)
            }
            if runtime.isWindowOperationRunning {
                ProgressView(runtime.isPreviewRunning ? "Selected-window capture · maximum 5 seconds…" : "Checking native window state…")
                    .controlSize(.small)
            }
            if let message = runtime.windowMessage {
                Text(message).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(filteredWindows) { window in
                    windowRow(window)
                    Divider()
                }
            }
            if filteredWindows.isEmpty && !runtime.isWindowOperationRunning {
                ContentUnavailableView("No matching windows", systemImage: "macwindow",
                                       description: Text("Open Test Lab, grant Accessibility explicitly, then refresh."))
            }
        }
        .task(id: requestID) { await runtime.performWindowCommand(command) }
        .onDisappear { runtime.removePreviewOverlay() }
    }

    private var filteredWindows: [WindowDescriptor] {
        runtime.windows.filter {
            (showReadOnly || $0.runtimeHandle != nil)
                && (search.isEmpty || $0.applicationName.localizedCaseInsensitiveContains(search)
                    || ($0.title?.localizedCaseInsensitiveContains(search) ?? false))
        }
    }

    private func windowRow(_ window: WindowDescriptor) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: window.runtimeHandle == nil ? "macwindow" : "checkmark.shield")
                    .foregroundStyle(window.runtimeHandle == nil ? Color.secondary : Color.teal)
                Text(window.applicationName).font(.headline)
                Spacer()
                Text("PID \(window.processID) / #\(window.id.rawValue)").font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            Text(window.title.flatMap { $0.isEmpty ? nil : $0 } ?? "Title unavailable")
                .lineLimit(1).textSelection(.enabled)
            HStack(spacing: 12) {
                capability("Move", enabled: window.capabilities.canSetPosition)
                capability("Resize", enabled: window.capabilities.canSetSize)
                capability("Focus", enabled: window.capabilities.canFocus)
                if window.isMinimized { Text("Minimized").font(.caption) }
                if !window.isOnScreen { Text("Off-screen").font(.caption) }
                Spacer()
                Button("Preview 5s") { if let handle = window.runtimeHandle { submit(.preview(handle)) } }
                    .disabled(window.runtimeHandle == nil || !runtime.screenRecordingGranted || !window.isOnScreen || window.isMinimized)
                    .help("Capture this window on demand; excluded applications are rejected before capture")
                Button("Focus") { if let handle = window.runtimeHandle { submit(.focus(handle)) } }
                    .disabled(window.runtimeHandle == nil || !window.capabilities.canFocus)
                Button("Center") { position(window, half: false) }
                    .disabled(window.runtimeHandle == nil || !window.capabilities.canSetPosition)
                Button("Left half") { position(window, half: true) }
                    .disabled(window.runtimeHandle == nil || !window.capabilities.canSetPosition || !window.capabilities.canSetSize)
            }
            .disabled(runtime.isWindowOperationRunning)
            if window.runtimeHandle == nil {
                Text("Read-only · no unambiguous AX match in this session").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 16)
    }

    private func capability(_ title: String, enabled: Bool) -> some View {
        Label(title, systemImage: enabled ? "checkmark.circle.fill" : "minus.circle")
            .font(.caption).foregroundStyle(enabled ? Color.teal : Color.secondary)
    }

    private func submit(_ command: WindowPanelCommand) {
        self.command = command
        requestID = UUID()
    }

    /// Use the target display's visible frame, converted to CG's global top-left coordinates.
    private func position(_ window: WindowDescriptor, half: Bool) {
        guard let handle = window.runtimeHandle, let original = window.frame?.cgRect,
              let primary = NSScreen.screens.first,
              let screen = NSScreen.screens.first(where: {
                  ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == window.displayID?.rawValue
              }) ?? NSScreen.main else { return }
        let visible = WindowGeometry.fromAppKit(screen.visibleFrame, primaryDisplayHeight: primary.frame.height)
        let target: CGRect
        if half {
            target = CGRect(x: visible.minX, y: visible.minY, width: visible.width / 2, height: visible.height)
        } else {
            target = CGRect(x: visible.midX - original.width / 2, y: visible.midY - original.height / 2,
                            width: original.width, height: original.height)
        }
        submit(.setFrame(handle, CodableRect(target)))
    }
}