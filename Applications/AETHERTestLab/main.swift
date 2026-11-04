import SwiftUI
import AppKit

@main
struct AETHERTestLabApp: App {
    var body: some Scene {
        WindowGroup("AETHER Test Lab") {
            TestLabView()
                .frame(minWidth: 700, minHeight: 500)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open Test Window") { TestWindowController.shared.openWindow() }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }
}

struct TestLabView: View {
    @State private var counter = 0
    @State private var isAnimated = true

    var body: some View {
        VStack(spacing: 20) {
            Text("AETHER Test Lab").font(.largeTitle.bold())
            Text("Controlled window fixtures for discovery, capture and overlay integration tests.")
                .foregroundStyle(.secondary)
            HStack {
                Button("Open Window") { TestWindowController.shared.openWindow() }
                Button("Increment Content") { counter += 1 }
                Toggle("Animate", isOn: $isAnimated)
                    .toggleStyle(.switch)
            }
            Text("Dynamic content: \(counter)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .padding(40)
                .background(.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 20))
            Spacer()
            Text("Also create manual fixtures: fixed-size, transparent, fullscreen and multi-window.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(30)
    }
}

@MainActor
final class TestWindowController {
    static let shared = TestWindowController()
    private var windows: [NSWindow] = []

    func openWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 120, y: 120, width: 520, height: 340),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "AETHER Fixture \(windows.count + 1)"
        window.contentView = NSHostingView(rootView: FixtureView())
        window.makeKeyAndOrderFront(nil)
        windows.append(window)
    }
}

struct FixtureView: View {
    @State private var value = 0
    var body: some View {
        VStack(spacing: 18) {
            Text("AETHER Window Fixture").font(.title.bold())
            Text("Change content while AETHER captures this window.")
            Text("Value: \(value)").font(.system(size: 42, weight: .semibold))
            Button("Update") { value += 1 }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
