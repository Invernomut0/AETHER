import Foundation
import CoreGraphics
import AppKit
import AETHERShared

@MainActor
public final class CoreGraphicsWindowDiscovery: WindowDiscovering {
    public init() {}

    public func refresh() async throws -> [WindowDescriptor] {
        guard let rows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        return rows.compactMap { row in
            guard let number = row[kCGWindowNumber as String] as? NSNumber,
                  let pid = row[kCGWindowOwnerPID as String] as? NSNumber else { return nil }
            let bounds = (row[kCGWindowBounds as String] as? NSDictionary)
                .flatMap { CGRect(dictionaryRepresentation: $0) }
            let frame = bounds.map(CodableRect.init)
            let title = row[kCGWindowName as String] as? String
            let appName = row[kCGWindowOwnerName as String] as? String ?? "Unknown"
            return WindowDescriptor(
                id: WindowID(rawValue: number.uint32Value),
                processID: pid.int32Value,
                bundleIdentifier: nil,
                applicationName: appName,
                title: title,
                frame: frame,
                displayID: nil,
                isOnScreen: true,
                isMinimized: false,
                capabilities: WindowCapabilities()
            )
        }
    }
}
