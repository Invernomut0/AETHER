import Foundation

public enum AetherError: Error, Sendable, Equatable {
    case permissionDenied(String)
    case unsupported(String)
    case notFound(String)
    case invalidState(String)
    case operationFailed(String)
    case timeout(String)
    case resourceUnavailable(String)
    case cancelled
}
