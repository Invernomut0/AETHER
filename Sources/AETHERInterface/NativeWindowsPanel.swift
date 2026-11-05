import SwiftUI
import AppKit
import AETHERCore
import AETHERShared
import AETHERWindowManager

enum WindowPanelCommand {
    case refresh
    case focus(RuntimeWindowHandle)
    case setFrame(RuntimeWindowHandle, CodableRect)
    case preview(RuntimeWindowHandle)
    case livePreview(RuntimeWindowHandle)
    case effect(RuntimeWindowHandle, WindowEffectKind)
}

/// Native instrument-panel styling: compact capability labels and explicit, guarded commands.
struct NativeWindowsPanel: View {
    let runtime: AetherRuntimeModel
    @State private var kinetiq = KinetiqEngineCoordinator.shared
    @State private var requestID = UUID()
    @State private var command: WindowPanelCommand = .refresh
    @State private var search = ""
    @State private var showReadOnly = true
    @State private var closeTarget: RuntimeWindowHandle?
    @State private var closeTitle = ""
    @State private var showCloseConfirmation = false

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
                    Button("Stop overlay", systemImage: "stop.fill") {
                        runtime.removePreviewOverlay()
                        submit(.refresh)
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            Text("Native control needs Accessibility only. Snapshot 5s captures one static image, not a recording stream. Live diagnostic continuously captures and macOS may show recording indicators. Both require Screen Recording consent, never move or hide the original, and end if the target changes.")
                .font(.callout).foregroundStyle(.secondary)
            if kinetiq.isActive {
                Label("Kinetiq owns desktop effects. Stop Kinetiq in Effects before using these native controls or diagnostic overlays. Refresh remains available.", systemImage: "water.waves")
                    .font(.callout).foregroundStyle(.orange)
            } else {
                Text("For real global wobbly dragging and Kinetiq close shaders, open Effects. The controls below are independent AETHER diagnostics.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            GroupBox("Visual indicator check · manual, not automatically passed") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("1. Filter for AETHER Test Lab and select Snapshot 5s. Watch the target title bar and macOS menu bar before, during and after capture.")
                    Text("2. Try Wobble 2s: an elastic snapshot preview, not a global native-drag replacement. The original remains visible and interactive.")
                    Text("3. On AETHER Effect Disposable, try Close with dissolve. This really closes that window after confirmation. Stop removes the effect but cannot undo the close.")
                    Text("Live diagnostic is an optional continuous-recording comparison, not the normal path. Recent-use/system indicators can persist; their absence is not guaranteed or suppressed.")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
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
                ProgressView(runtime.isPreviewRunning ? "Selected-window capture / temporary overlay…" : "Checking native window state…")
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
        .task {
            while !Task.isCancelled {
                kinetiq.refreshStatus()
                do { try await Task.sleep(for: .milliseconds(500)) }
                catch { return }
            }
        }
        .onDisappear { runtime.removePreviewOverlay() }
        .confirmationDialog("Close this native window?", isPresented: $showCloseConfirmation, titleVisibility: .visible) {
            Button("Close with dissolve", role: .destructive) {
                if let closeTarget { submit(.effect(closeTarget, .dissolveClose)) }
                closeTarget = nil
            }
            Button("Cancel", role: .cancel) { closeTarget = nil }
        } message: {
            Text("\(closeTitle)\nThis sends one native close request. Save any work first. If the app refuses or opens a save dialog, the effect will not play. Stop cannot undo a close.")
        }
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
                capability("Close", enabled: window.capabilities.canClose)
                if window.isMinimized { Text("Minimized").font(.caption) }
                if !window.isOnScreen { Text("Off-screen").font(.caption) }
                Spacer()
                Button("Focus") { if let handle = window.runtimeHandle { submit(.focus(handle)) } }
                    .disabled(window.runtimeHandle == nil || !window.capabilities.canFocus)
                Button("Center") { position(window, half: false) }
                    .disabled(window.runtimeHandle == nil || !window.capabilities.canSetPosition)
                Button("Left half") { position(window, half: true) }
                    .disabled(window.runtimeHandle == nil || !window.capabilities.canSetPosition || !window.capabilities.canSetSize)
            }
            .disabled(runtime.isWindowOperationRunning || kinetiq.isActive)
            HStack(spacing: 12) {
                Button("Snapshot 5s") { if let handle = window.runtimeHandle { submit(.preview(handle)) } }
                    .disabled(window.runtimeHandle == nil || !runtime.screenRecordingGranted || !window.isOnScreen || window.isMinimized)
                    .help("One static screenshot held for five seconds; no continuous SCStream. System privacy policy still applies.")
                Button("Live diagnostic") { if let handle = window.runtimeHandle { submit(.livePreview(handle)) } }
                    .disabled(window.runtimeHandle == nil || !runtime.screenRecordingGranted || !window.isOnScreen || window.isMinimized)
                    .help("Explicit continuous recording for up to five seconds. macOS recording indicators are expected.")
                Button("Wobble 2s") { if let handle = window.runtimeHandle { submit(.effect(handle, .wobble)) } }
                    .help("Animate one captured texture with an independent spring lattice; no stream or native drag interception.")
                Button("Close with dissolve…") {
                    closeTarget = window.runtimeHandle
                    closeTitle = "\(window.applicationName) — \(window.title ?? "Untitled window")"
                    showCloseConfirmation = true
                }
                .disabled(!window.capabilities.canClose)
                .help("Destructive: request a real native close, then animate only after verified disappearance. Requires confirmation.")
            }
            .disabled(runtime.isWindowOperationRunning || kinetiq.isActive || window.runtimeHandle == nil || !runtime.screenRecordingGranted || !window.isOnScreen || window.isMinimized)
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