// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AETHER",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AETHERShared", targets: ["AETHERShared"]),
        .library(name: "AETHERCore", targets: ["AETHERCore"]),
        .library(name: "AETHERWindowManager", targets: ["AETHERWindowManager"]),
        .library(name: "AETHERCapture", targets: ["AETHERCapture"]),
        .library(name: "AETHERRendering", targets: ["AETHERRendering"]),
        .library(name: "AETHEREffects", targets: ["AETHEREffects"]),
        .library(name: "AETHERPhysics", targets: ["AETHERPhysics"]),
        .library(name: "AETHERAnimation", targets: ["AETHERAnimation"]),
        .library(name: "AETHERLayouts", targets: ["AETHERLayouts"]),
        .library(name: "AETHERPersistence", targets: ["AETHERPersistence"]),
        .library(name: "AETHERIntelligence", targets: ["AETHERIntelligence"]),
        .library(name: "AETHERInterface", targets: ["AETHERInterface"])
    ],
    targets: [
        .target(name: "AETHERShared", exclude: ["README.md"]),
        .target(name: "AETHERCore", dependencies: ["AETHERShared", "AETHERPersistence"], exclude: ["README.md"]),
        .target(name: "AETHERWindowManager", dependencies: ["AETHERShared"], exclude: ["README.md"]),
        .target(name: "AETHERCapture", dependencies: ["AETHERShared"], exclude: ["README.md"]),
        .target(name: "AETHERRendering", dependencies: ["AETHERShared"], exclude: ["README.md"], resources: [.process("Shaders")]),
        .target(name: "AETHEREffects", dependencies: ["AETHERShared", "AETHERAnimation", "AETHERRendering"], exclude: ["README.md"]),
        .target(name: "AETHERPhysics", dependencies: ["AETHERShared"], exclude: ["README.md"]),
        .target(name: "AETHERAnimation", dependencies: ["AETHERShared"], exclude: ["README.md"]),
        .target(name: "AETHERLayouts", dependencies: ["AETHERShared"], exclude: ["README.md"]),
        .target(name: "AETHERPersistence", dependencies: ["AETHERShared"], exclude: ["README.md"]),
        .target(name: "AETHERIntelligence", dependencies: ["AETHERShared", "AETHERLayouts"], exclude: ["README.md"]),
        .target(name: "AETHERInterface", dependencies: ["AETHERShared", "AETHERCore", "AETHEREffects", "AETHERWindowManager"], exclude: ["README.md"]),
        .testTarget(name: "AETHERWindowManagerTests", dependencies: ["AETHERWindowManager", "AETHERShared"]),
        .testTarget(name: "AETHERSharedTests", dependencies: ["AETHERShared"]),
        .testTarget(name: "AETHERCoreTests", dependencies: ["AETHERCore", "AETHERPersistence"]),
        .testTarget(name: "AETHERPersistenceTests", dependencies: ["AETHERPersistence"]),
        .testTarget(name: "AETHERPhysicsTests", dependencies: ["AETHERPhysics"]),
        .testTarget(name: "AETHERLayoutsTests", dependencies: ["AETHERLayouts"]),
        .testTarget(name: "AETHERAnimationTests", dependencies: ["AETHERAnimation"])
    ],
    swiftLanguageModes: [.v6]
)
