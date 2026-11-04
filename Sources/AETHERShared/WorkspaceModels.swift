import Foundation

public enum LayoutNodeKind: String, Codable, Sendable {
    case horizontalSplit, verticalSplit, stack, leaf, floating
}

public struct LayoutNode: Codable, Sendable, Identifiable {
    public var id: UUID
    public var kind: LayoutNodeKind
    public var children: [LayoutNode]
    public var windowID: WindowID?
    public var ratio: Double?

    public init(id: UUID, kind: LayoutNodeKind, children: [LayoutNode], windowID: WindowID?, ratio: Double?) {
        self.id = id
        self.kind = kind
        self.children = children
        self.windowID = windowID
        self.ratio = ratio
    }
}

public struct WindowGroupDescriptor: Codable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    public var windowIDs: [WindowID]
}

public struct WorkspaceDescriptor: Codable, Sendable, Identifiable {
    public var id: WorkspaceID
    public var name: String
    public var layoutID: UUID?
    public var groups: [WindowGroupDescriptor]
}
