import Foundation
import AETHERShared

public struct LayoutEngine: LayoutComputing {
    public init() {}

    public func validate(_ root: LayoutNode) throws {
        var seen = Set<WindowID>()
        try walk(root, seen: &seen)
    }

    private func walk(_ node: LayoutNode, seen: inout Set<WindowID>) throws {
        if node.kind == .leaf {
            guard let id = node.windowID else {
                throw AetherError.invalidState("Leaf layout node must reference a window")
            }
            guard seen.insert(id).inserted else {
                throw AetherError.invalidState("A window appears more than once in a layout")
            }
        }
        if let ratio = node.ratio, !(0.05...0.95).contains(ratio) {
            throw AetherError.invalidState("Split ratio must be between 0.05 and 0.95")
        }
        for child in node.children { try walk(child, seen: &seen) }
    }

    public func frames(for root: LayoutNode, in bounds: CodableRect, spacing: Double) throws -> [WindowID: CodableRect] {
        try validate(root)
        var output: [WindowID: CodableRect] = [:]
        try compute(root, rect: bounds.cgRect, spacing: max(0, spacing), output: &output)
        return output
    }

    private func compute(_ node: LayoutNode, rect: CGRect, spacing: Double,
                         output: inout [WindowID: CodableRect]) throws {
        if node.kind == .leaf, let id = node.windowID {
            output[id] = CodableRect(rect)
            return
        }
        guard !node.children.isEmpty else { return }
        if node.kind == .horizontalSplit || node.kind == .verticalSplit {
            guard node.children.count == 2 else {
                throw AetherError.invalidState("Split nodes currently require exactly two children")
            }
            let ratio = min(max(node.ratio ?? 0.5, 0.05), 0.95)
            if node.kind == .horizontalSplit {
                let available = max(0, rect.width - spacing)
                let first = available * ratio
                try compute(node.children[0], rect: CGRect(x: rect.minX, y: rect.minY, width: first, height: rect.height), spacing: spacing, output: &output)
                try compute(node.children[1], rect: CGRect(x: rect.minX + first + spacing, y: rect.minY, width: available - first, height: rect.height), spacing: spacing, output: &output)
            } else {
                let available = max(0, rect.height - spacing)
                let first = available * ratio
                try compute(node.children[0], rect: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: first), spacing: spacing, output: &output)
                try compute(node.children[1], rect: CGRect(x: rect.minX, y: rect.minY + first + spacing, width: rect.width, height: available - first), spacing: spacing, output: &output)
            }
        } else {
            for child in node.children { try compute(child, rect: rect, spacing: spacing, output: &output) }
        }
    }
}
