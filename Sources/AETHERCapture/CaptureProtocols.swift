import Foundation
import AETHERShared

public protocol WindowCapturing: Sendable {
    func startCapture(windowID: WindowID) async throws -> CaptureSessionID
    func startCapture(request: CaptureRequest) async throws -> CaptureSessionID
    func frames(sessionID: CaptureSessionID) async throws -> AsyncThrowingStream<CapturedFrame, any Error>
    func stopCapture(sessionID: CaptureSessionID) async
    func stopCaptureReportingErrors(sessionID: CaptureSessionID) async throws
    func isCapturing(sessionID: CaptureSessionID) async -> Bool
}
