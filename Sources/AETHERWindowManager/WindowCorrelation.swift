import Foundation
import AETHERShared

/// Value snapshot only. AXUIElement ownership never leaves the session actor.
struct AXWindowMetadata: Sendable {
    let processID: Int32
    let frame: CGRect?
    let title: String?
    let isMinimized: Bool
    let capabilities: WindowCapabilities
}

/// No public API exposes a universal AX-to-CG ID mapping. Accept only mutually unique matches.
enum WindowCorrelation {
    static func matches(native: [WindowDescriptor], accessibility: [AXWindowMetadata]) -> [WindowID: Int] {
        var candidates: [WindowID: [Int]] = [:]
        var reverseCounts: [Int: Int] = [:]
        for window in native {
            guard let frame = window.frame?.cgRect else { continue }
            let indices = accessibility.indices.filter { index in
                let ax = accessibility[index]
                guard window.processID == ax.processID, let axFrame = ax.frame,
                      WindowGeometry.approximatelyEqual(frame, axFrame) else { return false }
                // Titles are optional and can be redacted. When both exist, disagreement fails closed.
                if let title = window.title, !title.isEmpty,
                   let axTitle = ax.title, !axTitle.isEmpty { return title == axTitle }
                return true
            }
            candidates[window.id] = indices
            for index in indices { reverseCounts[index, default: 0] += 1 }
        }
        return candidates.reduce(into: [:]) { result, item in
            guard item.value.count == 1, let index = item.value.first,
                  reverseCounts[index] == 1 else { return }
            result[item.key] = index
        }
    }
}