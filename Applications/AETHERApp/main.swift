import SwiftUI
import AETHERInterface

@main
struct AETHERApp: App {
    @State private var runtime = AetherRuntimeModel()

    var body: some Scene {
        WindowGroup {
            AetherDashboardView(runtime: runtime)
                .frame(minWidth: 900, minHeight: 620)
                .task { await runtime.start() }
        }
        .windowResizability(.contentSize)
    }
}
