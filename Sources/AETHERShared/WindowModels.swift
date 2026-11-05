import Foundation

public struct WindowCapabilities: Codable, Sendable, Equatable {
    public var canReadFrame: Bool
    public var canSetPosition: Bool
    public var canSetSize: Bool
    public var canFocus: Bool
    public var canCapture: Bool
    /// True only when the native close button is enabled and advertises AXPress.
    public var canClose: Bool
    public init(canReadFrame: Bool = false, canSetPosition: Bool = false,
                canSetSize: Bool = false, canFocus: Bool = false, canCapture: Bool = false,
                canClose: Bool = false) {
        self.canReadFrame = canReadFrame
        self.canSetPosition = canSetPosition
        self.canSetSize = canSetSize
        self.canFocus = canFocus
        self.canCapture = canCapture
        self.canClose = canClose
    }

    private enum CodingKeys: String, CodingKey {
        case canReadFrame, canSetPosition, canSetSize, canFocus, canCapture, canClose
    }

    /// Older capability records have no close authorization; never infer it on decode.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        canReadFrame = try values.decode(Bool.self, forKey: .canReadFrame)
        canSetPosition = try values.decode(Bool.self, forKey: .canSetPosition)
        canSetSize = try values.decode(Bool.self, forKey: .canSetSize)
        canFocus = try values.decode(Bool.self, forKey: .canFocus)
        canCapture = try values.decode(Bool.self, forKey: .canCapture)
        canClose = try values.decodeIfPresent(Bool.self, forKey: .canClose) ?? false
    }
}

public struct WindowDescriptor: Identifiable, Sendable, Equatable {
    public let id: WindowID
    public let processID: Int32
    public let bundleIdentifier: String?
    public let applicationName: String
    public let title: String?
    public let frame: CodableRect?
    public let displayID: DisplayID?
    public let isOnScreen: Bool
    public let isMinimized: Bool
    public let capabilities: WindowCapabilities
    /// Present only when an unambiguous AX element has been registered in this session.
    public let runtimeHandle: RuntimeWindowHandle?

    public init(id: WindowID, processID: Int32, bundleIdentifier: String?,
                applicationName: String, title: String?, frame: CodableRect?,
                displayID: DisplayID?, isOnScreen: Bool, isMinimized: Bool,
                capabilities: WindowCapabilities, runtimeHandle: RuntimeWindowHandle? = nil) {
        self.id = id; self.processID = processID; self.bundleIdentifier = bundleIdentifier
        self.applicationName = applicationName; self.title = title; self.frame = frame
        self.displayID = displayID; self.isOnScreen = isOnScreen
        self.isMinimized = isMinimized; self.capabilities = capabilities
        self.runtimeHandle = runtimeHandle
    }
}

public enum WindowPresentationState: String, Codable, Sendable {
    case normal, tiled, maximized, minimized, fullscreen, hidden, transitioning, unavailable
}

public struct WindowState: Codable, Sendable {
    public var handle: RuntimeWindowHandle
    public var frame: CodableRect?
    public var presentation: WindowPresentationState
    public var isFocused: Bool
    public var isVisible: Bool
    public var activeEffects: [EffectID]
}
