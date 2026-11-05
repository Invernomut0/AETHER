import AppKit
import Carbon
import CoreGraphics
import Foundation
import AETHERShared
import AETHERWindowManager
import AETHERCapture
import AETHERRendering
import AETHERPhysics

/// Explicit operations only; neither case intercepts third-party dragging or the red close button.
public enum WindowEffectKind: Sendable {
    case wobble
    case dissolveClose
}

public struct WindowEffectReport: Sendable {
    public let kind: WindowEffectKind
    public let framesPresented: UInt64
    public let overlayRemoved: Bool
    public let nativeWindowClosed: Bool
    public let reducedMotion: Bool
}

/// A bounded, user-requested effect over ONE immutable snapshot, not a recording loop.
/// Wobble never changes the native window. Close sends exactly one supported AX request;
/// only confirmed native disappearance permits its animation. Stop cannot undo a close.
@MainActor
public final class WindowEffectCoordinator {
    private let windows: NativeWindowService
    private let capture = ScreenCaptureCoordinator()
    private var renderer: MetalOverlayPresenter?
    private var running = false
    private var stopRequested = false
    public private(set) var framesPresented: UInt64 = 0
    public var isOverlayVisible: Bool { renderer?.diagnostics().isVisible ?? false }

    public init(windows: NativeWindowService) { self.windows = windows }

    /// Immediate visual removal; the owning structured task is also cancelled by the UI.
    public func removeOverlay() {
        stopRequested = true
        renderer?.remove()
    }

    /// Duration controls only animation, not capture/AX deadlines. System Reduce Motion
    /// replaces deformation/noise with a simple fade. No frames or titles are persisted.
    public func perform(_ kind: WindowEffectKind, on handle: RuntimeWindowHandle,
                        configuration: AetherConfiguration,
                        duration: Duration = .seconds(2)) async throws -> WindowEffectReport {
        try Task.checkCancellation()
        guard !running else { throw AetherError.invalidState("Another effect is still cleaning up") }
        guard configuration.effectsEnabled, duration >= .milliseconds(200), duration <= .seconds(3) else {
            throw AetherError.invalidState("Effects are disabled or duration is outside 0.2...3 seconds")
        }
        running = true
        stopRequested = false
        framesPresented = 0
        defer { running = false }
        var closeRequested = false
        var nativeClosed = false
        let reducedMotion = configuration.reduceMotion || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        do {
            let original = try await windows.validatedWindow(handle)
            guard kind != .dissolveClose || original.capabilities.canClose else {
                throw AetherError.unsupported("This window has no enabled public AX close action")
            }
            let request = try CaptureRequest(window: original, excludedBundleIDs: configuration.captureExcludedBundleIDs)
            try await capture.stopAllCaptures()
            try checkStopped()
            let snapshot = try await capture.captureSnapshot(request: request)
            try checkStopped()
            let current = try await windows.validatedWindow(handle)
            try requireUnchanged(current, original)
            guard ProcessInfo.processInfo.systemUptime - snapshot.receivedAtUptime <= 1,
                  let rect = original.frame?.cgRect else {
                throw AetherError.timeout("Effect snapshot was stale before upload")
            }
            try requirePrivacy()
            if renderer == nil { renderer = MetalOverlayPresenter() }
            guard let renderer else { throw AetherError.resourceUnavailable("Effect renderer unavailable") }
            // Padding contains the bounded displacement, without moving/hiding the original.
            let padding: CGFloat = kind == .wobble ? min(rect.width, rect.height) * 0.26 : 0
            let canvas = rect.insetBy(dx: -padding, dy: -padding)
            try renderer.prepareEffect(snapshot.pixels, frame: canvas,
                                       relativeTo: kind == .dissolveClose ? 0 : Int(handle.windowID.rawValue))
            try checkStopped()
            if kind == .dissolveClose {
                closeRequested = true
                try await windows.close(handle)
                nativeClosed = true
                try checkStopped()
                guard ProcessInfo.processInfo.systemUptime - snapshot.receivedAtUptime <= 3 else {
                    throw AetherError.timeout("Native window closed, but the effect snapshot is too old")
                }
            }
            try await animate(kind, original: original, rect: rect, canvas: canvas,
                              padding: padding, duration: duration, reducedMotion: reducedMotion)
            renderer.remove()
            try await capture.stopAllCaptures()
            if kind == .wobble {
                try requireUnchanged(try await windows.validatedWindow(handle), original)
            } else {
                guard try windows.isWindowClosed(handle) else {
                    throw AetherError.invalidState("Native window reappeared during close effect")
                }
            }
            return WindowEffectReport(kind: kind, framesPresented: framesPresented,
                                      overlayRemoved: !isOverlayVisible, nativeWindowClosed: nativeClosed,
                                      reducedMotion: reducedMotion)
        } catch {
            renderer?.remove()
            do { try await capture.stopAllCaptures() }
            catch { throw AetherError.operationFailed("Effect capture cleanup unconfirmed; retry Stop: \(error)") }
            if error is NativeWindowCloseError { throw error }
            if closeRequested {
                throw AetherError.operationFailed("\(nativeClosed ? "Native window closed" : "Native close may have been requested"); Stop cannot undo it. Inspect the application before retrying. \(error)")
            }
            throw error
        }
    }

    private func animate(_ kind: WindowEffectKind, original: WindowDescriptor,
                         rect: CGRect, canvas: CGRect, padding: CGFloat,
                         duration: Duration, reducedMotion: Bool) async throws {
        guard let renderer, let handle = original.runtimeHandle else {
            throw AetherError.invalidState("Effect lost its renderer or runtime identity")
        }
        var simulation = try WobbleSimulation(size: SIMD2(Float(rect.width), Float(rect.height)))
        if kind == .wobble && !reducedMotion {
            try simulation.impulse(SIMD2(850, 320), at: SIMD2(0.18, 0.12))
        }
        let clock = ContinuousClock()
        let started = clock.now
        var previous = started
        var nextNativeCheck = started.advanced(by: .milliseconds(500))
        let total = seconds(duration)
        while true {
            try checkStopped()
            try requirePrivacy()
            let now = clock.now
            let progress = Float(min(1, seconds(now - started) / total))
            if kind == .wobble {
                try requireVisibleUnchanged(original)
                if now >= nextNativeCheck {
                    try requireUnchanged(try await windows.validatedWindow(handle), original)
                    nextNativeCheck = clock.now.advanced(by: .milliseconds(500))
                }
                try simulation.advance(by: seconds(now - previous))
            } else if try !windows.isWindowClosed(handle) {
                throw AetherError.invalidState("Native closure no longer confirmed; effect removed")
            }
            previous = now
            let fade = kind == .wobble ? max(0, (progress - 0.8) / 0.2) : progress
            let opacity: Float = (reducedMotion || kind == .wobble) ? 1 - fade : 1
            let dissolve: Float = (kind == .dissolveClose && !reducedMotion) ? progress : 0
            let vertices = mesh(simulation, rect: rect, canvas: canvas, padding: padding,
                                deform: kind == .wobble && !reducedMotion)
            try checkStopped() // AX validation above can suspend while Stop removes the overlay.
            try await renderer.renderEffect(vertices: vertices, opacity: opacity, dissolve: dissolve)
            try checkStopped()
            framesPresented += 1
            if progress >= 1 { break }
            // Monotonic, bounded, no idle display loop. Slow GPU work does not queue frames.
            let nextFrame = now.advanced(by: .nanoseconds(16_666_667))
            if clock.now < nextFrame { try await clock.sleep(until: nextFrame) }
        }
    }

    /// Row-major lattice to an independently generated triangle list; UVs never deform.
    private func mesh(_ simulation: WobbleSimulation, rect: CGRect, canvas: CGRect,
                      padding: CGFloat, deform: Bool) -> [OverlayVertex] {
        let offsets = simulation.displacements
        func vertex(_ column: Int, _ row: Int) -> OverlayVertex {
            let u = Float(column) / Float(simulation.columns - 1)
            let v = Float(row) / Float(simulation.rows - 1)
            let displacement = deform ? offsets[row * simulation.columns + column] : .zero
            let x = Float(padding) + u * Float(rect.width) + displacement.x
            let y = Float(padding) + v * Float(rect.height) + displacement.y
            return OverlayVertex(position: SIMD2(2 * x / Float(canvas.width) - 1,
                                                  1 - 2 * y / Float(canvas.height)),
                                 textureCoordinate: SIMD2(u, v))
        }
        var result: [OverlayVertex] = []
        result.reserveCapacity((simulation.columns - 1) * (simulation.rows - 1) * 6)
        for row in 0..<(simulation.rows - 1) {
            for column in 0..<(simulation.columns - 1) {
                let a = vertex(column, row), b = vertex(column + 1, row)
                let c = vertex(column, row + 1), d = vertex(column + 1, row + 1)
                result.append(contentsOf: [a, c, b, b, c, d])
            }
        }
        return result
    }

    private func checkStopped() throws {
        try Task.checkCancellation()
        guard !stopRequested else { throw CancellationError() }
    }

    private func requirePrivacy() throws {
        guard CGPreflightScreenCaptureAccess(), !IsSecureEventInputEnabled() else {
            throw AetherError.permissionDenied("Effect blocked by Screen Recording denial or secure input")
        }
    }

    private func requireUnchanged(_ current: WindowDescriptor, _ original: WindowDescriptor) throws {
        guard current.runtimeHandle == original.runtimeHandle, current.isOnScreen, !current.isMinimized,
              let a = current.frame?.cgRect, let b = original.frame?.cgRect,
              WindowGeometry.approximatelyEqual(a, b) else {
            throw AetherError.invalidState("Native target changed; wobble preview removed without rollback")
        }
    }

    private func requireVisibleUnchanged(_ original: WindowDescriptor) throws {
        guard let rows = CGWindowListCopyWindowInfo(.optionIncludingWindow, original.id.rawValue) as? [[String: Any]],
              rows.count == 1, let row = rows.first,
              (row[kCGWindowNumber as String] as? NSNumber)?.uint32Value == original.id.rawValue,
              (row[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value == original.processID,
              (row[kCGWindowIsOnscreen as String] as? NSNumber)?.boolValue == true,
              let bounds = row[kCGWindowBounds as String] as? NSDictionary,
              let current = CGRect(dictionaryRepresentation: bounds), let initial = original.frame?.cgRect,
              WindowGeometry.approximatelyEqual(current, initial) else {
            throw AetherError.invalidState("Native target moved, resized, minimized or disappeared")
        }
    }

    private func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }
}