import Foundation
import AETHERShared

public protocol LayoutComputing: Sendable {
    func validate(_ root: LayoutNode) throws
    func frames(for root: LayoutNode, in bounds: CodableRect, spacing: Double) throws -> [WindowID: CodableRect]
}
