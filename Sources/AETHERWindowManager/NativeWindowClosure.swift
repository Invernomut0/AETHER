import Foundation
import CoreGraphics
import AETHERShared

/// AXPress may have reached the application even when IPC, cancellation or verification fails.
/// This error never authorizes animation or an automatic retry, and implies no rollback.
public enum NativeWindowCloseError: Error, LocalizedError, Sendable {
    case outcomeUnconfirmed(reason: String)

    public var errorDescription: String? {
        switch self {
        case .outcomeUnconfirmed(let reason):
            "Native close may have been requested and cannot be undone; disappearance is unconfirmed. \(reason)"
        }
    }
}

/// Full, unfiltered WindowServer membership: missing bounds/layer/on-screen metadata must not
/// turn minimization, hiding or an unsupported descriptor into proof of closure.
enum NativeWindowInventory {
    static func contains(_ handle: RuntimeWindowHandle) throws -> Bool {
        guard let rows = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] else {
            throw AetherError.resourceUnavailable("CoreGraphics closure inventory failed")
        }
        for row in rows {
            guard let number = row[kCGWindowNumber as String] as? NSNumber,
                  let pid = row[kCGWindowOwnerPID as String] as? NSNumber else {
                throw AetherError.resourceUnavailable("CoreGraphics closure inventory has incomplete identity")
            }
            guard number.uint32Value == handle.windowID.rawValue else { continue }
            guard pid.int32Value == handle.processID else {
                throw AetherError.notFound("Native window ID was reused by another process")
            }
            return true
        }
        return false
    }
}