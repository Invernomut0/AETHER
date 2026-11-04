import AppKit
import CoreGraphics
import Foundation
import Metal
import QuartzCore
import AETHERShared

public struct OverlayPresentationDiagnostics: Sendable {
    public let isVisible: Bool
    public let framesPresented: UInt64
    public let allocatedTextureBytes: UInt64
    public let lastError: String?
    public init(isVisible: Bool, framesPresented: UInt64, allocatedTextureBytes: UInt64, lastError: String?) {
        self.isVisible = isVisible
        self.framesPresented = framesPresented
        self.allocatedTextureBytes = allocatedTextureBytes
        self.lastError = lastError
    }
}

@MainActor
public final class MetalOverlayPresenter {
    private struct Backend {
        let device: MTLDevice
        let commandQueue: MTLCommandQueue
        let pipelineState: MTLRenderPipelineState
        let samplerState: MTLSamplerState
    }

    private final class OverlayPanel: NSPanel {
        override var canBecomeKey: Bool { false }
        override var canBecomeMain: Bool { false }
    }

    /// Retains GPU-owned resources until command-buffer completion.
    private struct InFlightSubmission {
        let generation: UInt64
        let commandBuffer: MTLCommandBuffer
        let drawable: CAMetalDrawable
        let sourceTexture: MTLTexture
        let sourceTextureBytes: UInt64
        let drawableTextureBytes: UInt64
    }
    private static let vertexFunctionName = "aether_preview_vertex"
    private static let fragmentFunctionName = "aether_preview_fragment"
    private static let completionTimeout: Duration = .milliseconds(750)
    private static let maximumFrameEdgePoints: CGFloat = 16_384
    private let backend: Backend?
    private let initializationError: String?
    private var panel: OverlayPanel?
    private var metalLayer: CAMetalLayer?
    private var framesPresented: UInt64 = 0
    private var panelDrawableBytes: UInt64 = 0
    private var lastError: String?
    private var generation: UInt64 = 0
    private var pendingDeadline: CallbackDeadline<Void>?
    private var inFlight: InFlightSubmission?
    public init() {
        do {
            backend = try Self.makeBackend()
            initializationError = nil
            lastError = nil
        } catch {
            let message = Self.errorMessage(for: error)
            backend = nil
            initializationError = message
            lastError = message
        }
    }
    public func present(_ pixels: BGRAPixelFrame, frame: CGRect, relativeTo windowNumber: Int) async throws {
        try Task.checkCancellation()
        try Self.validatePresentationInput(frame: frame, pixels: pixels, windowNumber: windowNumber)
        guard pendingDeadline == nil else { throw AetherError.operationFailed("Overlay presentation is already in flight") }
        guard inFlight == nil else { throw AetherError.operationFailed("Previous overlay submission is still completing") }
        guard let backend else {
            let message = initializationError ?? "Metal overlay backend is unavailable"
            lastError = message
            throw AetherError.resourceUnavailable(message)
        }
        generation &+= 1
        let currentGeneration = generation
        lastError = nil
        let scale = Self.displayScale(for: frame)
        let appKitFrame = Self.cgToAppKitFrame(frame)
        let isNewPanel = panel == nil
        let panel = ensurePanel(frame: appKitFrame, scale: scale, device: backend.device)
        if isNewPanel { panel.alphaValue = 0 } // Hide only on first creation to avoid live flicker.
        panel.order(.above, relativeTo: windowNumber)
        do {
            guard let metalLayer else { throw AetherError.invalidState("Metal layer is unavailable") }
            let drawableSize = Self.drawableSize(for: frame.size, scale: scale)
            metalLayer.contentsScale = scale
            metalLayer.drawableSize = drawableSize
            panelDrawableBytes = Self.textureBytes(width: Int(drawableSize.width), height: Int(drawableSize.height))
            guard let drawable = metalLayer.nextDrawable() else {
                throw AetherError.resourceUnavailable("Unable to acquire CAMetalDrawable")
            }
            let sourceTexture = try Self.makeSourceTexture(device: backend.device, pixels: pixels)
            let sourceTextureBytes = Self.textureBytes(width: pixels.width, height: pixels.height)
            let drawableTextureBytes = Self.textureBytes(width: Int(drawableSize.width), height: Int(drawableSize.height))
            let commandBuffer = try makeCommandBuffer(backend: backend, sourceTexture: sourceTexture, drawable: drawable)
            let deadline = CallbackDeadline<Void>()
            pendingDeadline = deadline
            inFlight = InFlightSubmission(generation: currentGeneration, commandBuffer: commandBuffer, drawable: drawable, sourceTexture: sourceTexture, sourceTextureBytes: sourceTextureBytes, drawableTextureBytes: drawableTextureBytes)
            var didCommit = false
            defer { if pendingDeadline === deadline { pendingDeadline = nil } }
            do {
                try await withTaskCancellationHandler {
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                        guard deadline.install(continuation, timeout: Self.completionTimeout) else { return }
                        commandBuffer.addCompletedHandler { [weak self] completedBuffer in
                            let status = completedBuffer.status
                            let completionError = completedBuffer.error?.localizedDescription
                            Task { @MainActor [weak self] in
                                self?.clearInFlightIfMatching(generation: currentGeneration)
                                _ = deadline.finish(Self.commandBufferResult(status: status, completionError: completionError))
                            }
                        }
                        commandBuffer.commit()
                        didCommit = true
                    }
                } onCancel: {
                    _ = deadline.finish(.failure(AetherError.cancelled))
                }
            } catch {
                if !didCommit { clearInFlightIfMatching(generation: currentGeneration) }
                throw error
            }
        } catch {
            handlePresentationFailure(error, generation: currentGeneration)
            throw error
        }
        guard currentGeneration == generation else { throw AetherError.cancelled }
        framesPresented &+= 1
        panel.alphaValue = 1
        panel.order(.above, relativeTo: windowNumber)
    }
    public func remove() {
        generation &+= 1
        _ = pendingDeadline?.finish(.failure(AetherError.cancelled))
        pendingDeadline = nil
        closePanel() // Keep `inFlight` retained until real GPU completion.
    }
    public func diagnostics() -> OverlayPresentationDiagnostics {
        OverlayPresentationDiagnostics(
            isVisible: (panel?.isVisible ?? false) && ((panel?.alphaValue ?? 0) > 0),
            framesPresented: framesPresented,
            allocatedTextureBytes: allocatedTextureBytes(),
            lastError: lastError ?? initializationError
        )
    }
    private func ensurePanel(frame: CGRect, scale: CGFloat, device: MTLDevice) -> OverlayPanel {
        if let panel, let metalLayer {
            panel.setFrame(frame, display: false)
            panel.level = .normal
            panel.ignoresMouseEvents = true
            panel.sharingType = .none
            panel.contentView?.frame = CGRect(origin: .zero, size: frame.size)
            metalLayer.frame = panel.contentView?.bounds ?? CGRect(origin: .zero, size: frame.size)
            metalLayer.contentsScale = scale
            return panel
        }
        let panel = OverlayPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .normal
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.sharingType = .none
        panel.collectionBehavior = [.transient, .ignoresCycle, .fullScreenAuxiliary]
        let hostView = NSView(frame: CGRect(origin: .zero, size: frame.size))
        hostView.autoresizingMask = [.width, .height]
        hostView.wantsLayer = true
        let metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.isOpaque = false
        metalLayer.contentsScale = scale
        metalLayer.frame = hostView.bounds
        metalLayer.drawableSize = Self.drawableSize(for: frame.size, scale: scale)
        metalLayer.minificationFilter = .linear
        metalLayer.magnificationFilter = .linear
        hostView.layer = metalLayer
        panel.contentView = hostView
        self.panel = panel
        self.metalLayer = metalLayer
        return panel
    }
    private func closePanel() {
        guard let panel else { return }
        panel.orderOut(nil)
        panel.close()
        self.panel = nil
        self.metalLayer = nil
        panelDrawableBytes = 0
    }
    private func handlePresentationFailure(_ error: any Error, generation failedGeneration: UInt64) {
        guard failedGeneration == generation else { return }
        generation &+= 1
        if case AetherError.cancelled = error {
            // Keep cancellation silent in diagnostics.
        } else {
            lastError = Self.errorMessage(for: error)
        }
        closePanel()
    }
    private func clearInFlightIfMatching(generation: UInt64) {
        guard let inFlight, inFlight.generation == generation else { return }
        self.inFlight = nil
    }
    private func allocatedTextureBytes() -> UInt64 {
        var total: UInt64 = (panel != nil) ? panelDrawableBytes : 0
        if let inFlight {
            total += inFlight.sourceTextureBytes
            if panel == nil { total += inFlight.drawableTextureBytes }
        }
        return total
    }
    private func makeCommandBuffer(backend: Backend, sourceTexture: MTLTexture, drawable: CAMetalDrawable) throws -> MTLCommandBuffer {
        guard let commandBuffer = backend.commandQueue.makeCommandBuffer() else {
            throw AetherError.resourceUnavailable("Unable to create MTLCommandBuffer")
        }
        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.colorAttachments[0].texture = drawable.texture
        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].storeAction = .store
        passDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor) else {
            throw AetherError.operationFailed("Unable to create render command encoder")
        }
        encoder.setRenderPipelineState(backend.pipelineState)
        encoder.setFragmentTexture(sourceTexture, index: 0)
        encoder.setFragmentSamplerState(backend.samplerState, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        return commandBuffer
    }
    private static func makeBackend() throws -> Backend {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw AetherError.resourceUnavailable("No compatible Metal device is available")
        }
        guard let commandQueue = device.makeCommandQueue() else {
            throw AetherError.resourceUnavailable("Unable to create Metal command queue")
        }
        let library = try makeLibrary(device: device)
        guard let vertexFunction = library.makeFunction(name: vertexFunctionName),
              let fragmentFunction = library.makeFunction(name: fragmentFunctionName) else {
            throw AetherError.notFound("Preview shader functions are missing")
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        let pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        guard let samplerState = device.makeSamplerState(descriptor: samplerDescriptor) else {
            throw AetherError.resourceUnavailable("Unable to create Metal sampler state")
        }
        return Backend(device: device, commandQueue: commandQueue, pipelineState: pipelineState, samplerState: samplerState)
    }
    private static func makeLibrary(device: MTLDevice) throws -> MTLLibrary {
        if let defaultLibrary = try? device.makeDefaultLibrary(bundle: .module) { return defaultLibrary }
        guard let url = Bundle.module.url(forResource: "Preview", withExtension: "metal", subdirectory: "Shaders")
                ?? Bundle.module.url(forResource: "Preview", withExtension: "metal") else {
            throw AetherError.notFound("Required shader resource Preview.metal is missing")
        }
        let source = try String(contentsOf: url, encoding: .utf8)
        return try device.makeLibrary(source: source, options: nil)
    }
    private static func makeSourceTexture(device: MTLDevice, pixels: BGRAPixelFrame) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: pixels.width, height: pixels.height, mipmapped: false)
        descriptor.usage = [.shaderRead]
        descriptor.storageMode = .shared
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw AetherError.resourceUnavailable("Unable to create source texture")
        }
        pixels.bytes.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            texture.replace(
                region: MTLRegionMake2D(0, 0, pixels.width, pixels.height),
                mipmapLevel: 0,
                withBytes: baseAddress,
                bytesPerRow: pixels.bytesPerRow
            )
        }
        return texture
    }
    static func cgToAppKitFrame(_ globalTopLeftFrame: CGRect) -> CGRect {
        let mainDisplayHeightInPoints = CGDisplayBounds(CGMainDisplayID()).height
        let convertedY = mainDisplayHeightInPoints - globalTopLeftFrame.origin.y - globalTopLeftFrame.height
        return CGRect(x: globalTopLeftFrame.origin.x, y: convertedY, width: globalTopLeftFrame.width, height: globalTopLeftFrame.height)
    }
    static func displayScale(for globalTopLeftFrame: CGRect) -> CGFloat {
        let screenNumberKey = NSDeviceDescriptionKey("NSScreenNumber")
        var selectedScale: CGFloat?
        var selectedArea: CGFloat = 0
        for screen in NSScreen.screens {
            guard let displayNumber = screen.deviceDescription[screenNumberKey] as? NSNumber else { continue }
            let displayID = CGDirectDisplayID(displayNumber.uint32Value)
            let intersection = CGDisplayBounds(displayID).intersection(globalTopLeftFrame)
            guard !intersection.isNull, !intersection.isEmpty else { continue }
            let area = intersection.width * intersection.height
            if area > selectedArea {
                selectedArea = area
                selectedScale = screen.backingScaleFactor
            }
        }
        return selectedScale ?? NSScreen.main?.backingScaleFactor ?? NSScreen.screens.first?.backingScaleFactor ?? 1
    }
    private static func drawableSize(for pointSize: CGSize, scale: CGFloat) -> CGSize {
        // Bound compositor allocations too, not only the capture upload texture.
        let boundedScale = min(scale, 3200 / max(pointSize.width, pointSize.height))
        return CGSize(width: max((pointSize.width * boundedScale).rounded(.up), 1),
                      height: max((pointSize.height * boundedScale).rounded(.up), 1))
    }
    private static func textureBytes(width: Int, height: Int) -> UInt64 {
        UInt64(max(width, 0)) * UInt64(max(height, 0)) * 4
    }
    private static func commandBufferResult(status: MTLCommandBufferStatus, completionError: String?) -> Result<Void, any Error> {
        switch status {
        case .completed:
            return .success(())
        case .error:
            return .failure(AetherError.operationFailed(completionError ?? "Metal command buffer failed"))
        case .notEnqueued, .enqueued, .committed, .scheduled:
            return .failure(AetherError.operationFailed("Metal command buffer completed in status \(status.rawValue)"))
        @unknown default:
            return .failure(AetherError.operationFailed("Unknown Metal command buffer status"))
        }
    }
    private static func validatePresentationInput(frame: CGRect, pixels: BGRAPixelFrame, windowNumber: Int) throws {
        guard windowNumber > 0 else { throw AetherError.invalidState("Overlay requires a positive target window number") }
        guard frame.origin.x.isFinite, frame.origin.y.isFinite, frame.size.width.isFinite, frame.size.height.isFinite else {
            throw AetherError.invalidState("Overlay frame origin and size must be finite")
        }
        guard frame.size.width > 0, frame.size.height > 0 else {
            throw AetherError.invalidState("Overlay frame must be non-empty")
        }
        guard frame.width <= maximumFrameEdgePoints, frame.height <= maximumFrameEdgePoints else {
            throw AetherError.invalidState("Overlay frame exceeds safety edge limit of \(Int(maximumFrameEdgePoints)) points")
        }
        let maxAbsEdge = max(max(abs(frame.minX), abs(frame.maxX)), max(abs(frame.minY), abs(frame.maxY)))
        guard maxAbsEdge <= maximumFrameEdgePoints else {
            throw AetherError.invalidState("Overlay frame position exceeds safety limit of \(Int(maximumFrameEdgePoints)) points")
        }
        let requiredBytes = pixels.bytesPerRow * pixels.height
        guard pixels.width > 0, pixels.height > 0, pixels.bytesPerRow > 0, requiredBytes > 0, pixels.bytes.count >= requiredBytes else {
            throw AetherError.invalidState("Overlay pixel source must have a positive raw buffer")
        }
    }
    private static func errorMessage(for error: any Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription { return description }
        return String(describing: error)
    }
}