import SwiftUI
import AppKit

@main
struct AETHERTestLabApp: App {
    var body: some Scene {
        WindowGroup("AETHER Test Lab") {
            TestLabView()
                .frame(minWidth: 760, minHeight: 540)
                .task {
                    TestWindowController.shared.installM1FixturesIfRequested(arguments: ProcessInfo.processInfo.arguments)
                }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open Resizable Fixture") { TestWindowController.shared.openResizableFixture() }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                Button("Open Fixed-Size Fixture") { TestWindowController.shared.openFixedSizeFixture() }
                    .keyboardShortcut("f", modifiers: [.command, .shift])
                Button("Open Overlapping Fixtures") { TestWindowController.shared.openOverlappingFixtures() }
                    .keyboardShortcut("o", modifiers: [.command, .shift])
            }
        }
    }
}

struct TestLabView: View {
    @State private var counter = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("AETHER Test Lab").font(.largeTitle.bold())
            Text("Live NSWindow fixtures for native control and explicit visual-effect checks.")
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Open Resizable Fixture") { TestWindowController.shared.openResizableFixture() }
                Button("Open Fixed-Size Fixture") { TestWindowController.shared.openFixedSizeFixture() }
                Button("Open Two Overlapping Fixtures") { TestWindowController.shared.openOverlappingFixtures() }
                Button("Increment Content") { counter += 1 }
            }

            Button("Open Effect Disposable") { TestWindowController.shared.openEffectDisposable() }

            Text("Dynamic content: \(counter)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .padding(40)
                .background(.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 20))

            VStack(spacing: 6) {
                Text("Launch with --m1-fixtures to spawn deterministic startup windows.")
                Text("Expected titles: Resizable A/B/Disposable, Fixed, and two identical Overlap windows.")
                Text("Includes a separate M2 disposable for capture interruption tests; relaunch before repeating the live suite.")
                Text("Use AETHER Effect Disposable for Close with dissolve; reopen it with the button above.")
                Text("AETHER Refuses Close deliberately declines native close requests to test safe failure.")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(30)
    }
}

@MainActor
final class TestWindowController {
    static let shared = TestWindowController()

    enum Titles {
        static let resizableA = "M1 Fixture Resizable A"
        static let resizableB = "M1 Fixture Resizable B"
        static let resizableDisposable = "M1 Fixture Resizable Disposable"
        static let captureDisposable = "M2 Fixture Capture Disposable"
        static let effectDisposable = "AETHER Effect Disposable"
        static let refusingClose = "AETHER Refuses Close"
        static let fixed = "M1 Fixture Fixed"
        static let overlap = "M1 Fixture Overlap"
    }

    private enum Frames {
        static let resizableA = NSRect(x: 140, y: 120, width: 640, height: 420)
        static let resizableB = NSRect(x: 220, y: 180, width: 620, height: 400)
        static let resizableDisposable = NSRect(x: 300, y: 240, width: 600, height: 380)
        static let fixed = NSRect(x: 380, y: 300, width: 460, height: 280)
        static let overlap = NSRect(x: 460, y: 360, width: 520, height: 320)
    }

    private var windows: [ObjectIdentifier: NSWindow] = [:]
    private var delegates: [ObjectIdentifier: FixtureWindowDelegate] = [:]
    private var didInstallLaunchFixtures = false
    private var manualResizableIndex = 0

    func installM1FixturesIfRequested(arguments: [String]) {
        guard arguments.contains("--m1-fixtures"), !didInstallLaunchFixtures else { return }
        didInstallLaunchFixtures = true
        openResizableFixture(title: Titles.resizableA, frame: Frames.resizableA)
        openResizableFixture(title: Titles.resizableB, frame: Frames.resizableB)
        openResizableFixture(title: Titles.resizableDisposable, frame: Frames.resizableDisposable)
        openFixedSizeFixture()
        openOverlappingFixtures()
        openResizableFixture(title: Titles.captureDisposable, frame: Frames.resizableDisposable.offsetBy(dx: 24, dy: 24))
        openEffectDisposable()
        openWindow(title: Titles.refusingClose, frame: Frames.resizableDisposable.offsetBy(dx: 72, dy: 72),
                   styleMask: [.titled, .closable, .miniaturizable, .resizable], allowsClose: false)
    }

    func openEffectDisposable() {
        if let existing = windows.values.first(where: { $0.title == Titles.effectDisposable }) {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        openResizableFixture(title: Titles.effectDisposable, frame: Frames.resizableDisposable.offsetBy(dx: 48, dy: 48))
    }

    func openResizableFixture() {
        manualResizableIndex += 1
        let title = String(format: "M1 Fixture Resizable Manual %02d", manualResizableIndex)
        let frame = NSRect(x: 140 + CGFloat(manualResizableIndex * 28),
                           y: 120 + CGFloat(manualResizableIndex * 24),
                           width: 640, height: 420)
        openResizableFixture(title: title, frame: frame)
    }

    func openFixedSizeFixture() {
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable]
        openWindow(title: Titles.fixed, frame: Frames.fixed, styleMask: styleMask, fixedContentSize: Frames.fixed.size)
    }

    func openOverlappingFixtures() {
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        openWindow(title: Titles.overlap, frame: Frames.overlap, styleMask: styleMask)
        openWindow(title: Titles.overlap, frame: Frames.overlap, styleMask: styleMask)
    }

    private func openResizableFixture(title: String, frame: NSRect) {
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        openWindow(title: title, frame: frame, styleMask: styleMask)
    }

    private func openWindow(
        title: String,
        frame: NSRect,
        styleMask: NSWindow.StyleMask,
        fixedContentSize: NSSize? = nil,
        allowsClose: Bool = true
    ) {
        let window = NSWindow(contentRect: frame, styleMask: styleMask, backing: .buffered, defer: false)
        window.title = title
        window.isReleasedWhenClosed = false
        if let fixedContentSize {
            window.contentMinSize = fixedContentSize
            window.contentMaxSize = fixedContentSize
        }
        window.contentView = NSHostingView(rootView: FixtureView(title: title))
        register(window, allowsClose: allowsClose)
        window.makeKeyAndOrderFront(nil)
    }

    private func register(_ window: NSWindow, allowsClose: Bool) {
        let key = ObjectIdentifier(window)
        let delegate = FixtureWindowDelegate(allowsClose: allowsClose) { [weak self, weak window] in
            guard let self, let window else { return }
            self.unregister(window)
        }
        delegates[key] = delegate
        windows[key] = window
        window.delegate = delegate
    }

    private func unregister(_ window: NSWindow) {
        let key = ObjectIdentifier(window)
        windows.removeValue(forKey: key)
        delegates.removeValue(forKey: key)
    }
}

private final class FixtureWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void
    private let allowsClose: Bool

    init(allowsClose: Bool, onClose: @escaping () -> Void) {
        self.allowsClose = allowsClose
        self.onClose = onClose
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool { allowsClose }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

struct FixtureView: View {
    let title: String
    @State private var value = 0

    var body: some View {
        VStack(spacing: 18) {
            Text(title).font(.title.bold())
            Text("Live fixture content for discovery, correlation and AX control tests.")
            Text("Value: \(value)").font(.system(size: 42, weight: .semibold))
            Button("Update") { value += 1 }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
