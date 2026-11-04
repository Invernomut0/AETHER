import Foundation
import ScreenCaptureKit
import CoreMedia
import AETHERShared

@available(macOS 14.0, *)
public actor ScreenCaptureCoordinator: WindowCapturing {
    private var streams: [CaptureSessionID: SCStream] = [:]

    public init() {}

    public func startCapture(windowID: WindowID) async throws -> CaptureSessionID {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        guard let window = content.windows.first(where: { $0.windowID == windowID.rawValue }) else {
            throw AetherError.notFound("ScreenCaptureKit window not found")
        }

        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()
        configuration.width = max(1, Int(window.frame.width * 2))
        configuration.height = max(1, Int(window.frame.height * 2))
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        configuration.queueDepth = 3
        let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)

        // A production implementation must attach an SCStreamOutput, start the stream,
        // publish CMSampleBuffer frames through a bounded async channel and own teardown.
        // This foundation intentionally does not report capture as active until that
        // output/stream lifecycle is implemented and tested.
        _ = stream
        throw AetherError.unsupported("Capture output pipeline is not implemented yet. Complete M2 before enabling this feature.")
    }

    public func stopCapture(sessionID: CaptureSessionID) async {
        guard let stream = streams.removeValue(forKey: sessionID) else { return }
        try? await stream.stopCapture()
    }

    public func isCapturing(sessionID: CaptureSessionID) async -> Bool {
        streams[sessionID] != nil
    }
}
