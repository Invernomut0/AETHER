import Foundation
import AETHERShared

public protocol WindowCapturing: Sendable {
    func startCapture(windowID: WindowID) async throws -> CaptureSessionID
    func stopCapture(sessionID: CaptureSessionID) async
    func isCapturing(sessionID: CaptureSessionID) async -> Bool
}
