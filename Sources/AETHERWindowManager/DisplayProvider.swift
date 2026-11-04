import Foundation
import CoreGraphics
import AETHERShared

public struct CoreGraphicsDisplayProvider: DisplayDiscovering {
    public init() {}
    public func displays() async -> [DisplaySnapshot] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &ids, &count) == .success else { return [] }
        return ids.prefix(Int(count)).map { id in
            let bounds = CGDisplayBounds(id)
            return DisplaySnapshot(
                id: DisplayID(rawValue: id),
                bounds: CodableRect(bounds),
                scale: Double(CGDisplayPixelsWide(id)) / max(bounds.width, 1),
                refreshRate: 0,
                isMain: CGDisplayIsMain(id) != 0
            )
        }
    }
}
