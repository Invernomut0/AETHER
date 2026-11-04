import Foundation
import Testing
import AppKit
import CoreGraphics
import Metal
import AETHERShared
@testable import AETHERRendering

@MainActor
@Suite("MetalOverlayPresenter real AppKit/Metal behavior", .serialized)
struct OverlayPresenterTests {
    @Test("Initialization diagnostics and remove() are stable and idempotent")
    func initializationAndRemoveIdempotency() {
        _ = NSApplication.shared
        let presenter = MetalOverlayPresenter()

        let initial = presenter.diagnostics()
        #expect(initial.framesPresented == 0)
        #expect(initial.allocatedTextureBytes == 0)
        #expect(initial.isVisible == false)

        if MTLCreateSystemDefaultDevice() != nil {
            #expect(initial.lastError == nil)
        } else {
            #expect(initial.lastError != nil)
        }

        presenter.remove()
        presenter.remove()

        let afterRemove = presenter.diagnostics()
        #expect(afterRemove.isVisible == false)
        #expect(afterRemove.allocatedTextureBytes == 0)
    }

    @Test("Coordinate conversion and display scale use real primary display metrics")
    func coordinateConversionAndScale() throws {
        let primaryHeight = CGDisplayBounds(CGMainDisplayID()).height
        let globalTopLeft = CGRect(x: 96, y: 128, width: 420, height: 260)
        let converted = MetalOverlayPresenter.cgToAppKitFrame(globalTopLeft)
        let expected = CGRect(
            x: globalTopLeft.minX,
            y: primaryHeight - globalTopLeft.minY - globalTopLeft.height,
            width: globalTopLeft.width,
            height: globalTopLeft.height
        )

        #expect(abs(converted.minX - expected.minX) <= 0.001)
        #expect(abs(converted.minY - expected.minY) <= 0.001)
        #expect(abs(converted.width - expected.width) <= 0.001)
        #expect(abs(converted.height - expected.height) <= 0.001)

        let mainScale = try #require(primaryDisplayScaleFactor(), "Unable to resolve backing scale for main display")
        let probeFrame = CGDisplayBounds(CGMainDisplayID()).insetBy(dx: 16, dy: 16)
        let scale = MetalOverlayPresenter.displayScale(for: probeFrame)
        #expect(abs(scale - mainScale) <= 0.01)
    }

    @Test("present() renders real system icon pixels and remove() tears down overlay")
    func presentAndRemoveWithRealSystemIconPixels() async throws {
        _ = NSApplication.shared

        let presenter = MetalOverlayPresenter()
        if MTLCreateSystemDefaultDevice() == nil {
            let diagnostics = presenter.diagnostics()
            _ = try #require(diagnostics.lastError, "Metal unavailable should surface diagnostics")
            return
        }

        let hostWindow = NSWindow(
            contentRect: NSRect(x: 140, y: 220, width: 460, height: 320),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        hostWindow.title = "OverlayPresenterTests Host"
        hostWindow.isReleasedWhenClosed = false
        hostWindow.makeKeyAndOrderFront(nil)
        hostWindow.orderFrontRegardless()
        hostWindow.displayIfNeeded()
        defer {
            hostWindow.orderOut(nil)
            hostWindow.close()
        }

        let hostWindowNumber = hostWindow.windowNumber
        _ = try #require(hostWindowNumber > 0 ? hostWindowNumber : nil,
                         "Host NSWindow did not expose a valid native window number")

        let hostCGBounds = try #require(await publishedBounds(windowNumber: hostWindowNumber),
                                        "Host NSWindow is not visible in the CG window list")
        let presenterFrame = CGRect(
            x: hostCGBounds.minX,
            y: hostCGBounds.minY,
            width: min(max(hostCGBounds.width, 1), 512),
            height: min(max(hostCGBounds.height, 1), 512)
        )

        let knownWindowNumbers = Set(NSApplication.shared.windows.map(\.windowNumber))
        let keyWindowBefore = NSApplication.shared.keyWindow?.windowNumber
        let mainWindowBefore = NSApplication.shared.mainWindow?.windowNumber
        let frontmostPIDBefore = NSWorkspace.shared.frontmostApplication?.processIdentifier

        let iconPath = "/System/Applications/Utilities/Terminal.app"
        let icon = NSWorkspace.shared.icon(forFile: iconPath)
        icon.size = NSSize(width: 256, height: 256)
        let iconCGImage = try makeCGImage(from: icon, sourcePath: iconPath)
        let pixels = try makeBGRAFrame(from: iconCGImage, maxEdge: 256)

        try await presenter.present(pixels, frame: presenterFrame, relativeTo: hostWindowNumber)

        let afterPresent = presenter.diagnostics()
        #expect(afterPresent.framesPresented > 0)
        #expect(afterPresent.isVisible)
        #expect(afterPresent.allocatedTextureBytes > 0)
        #expect(afterPresent.lastError == nil)

        let overlayPanel = try #require(
            NSApplication.shared.windows
                .compactMap { $0 as? NSPanel }
                .first(where: { panel in
                    !knownWindowNumbers.contains(panel.windowNumber)
                    && panel.styleMask.contains(.nonactivatingPanel)
                    && panel.ignoresMouseEvents
                    && panel.isVisible
                }),
            "No visible non-activating overlay panel was discovered after present()"
        )

        #expect(overlayPanel.ignoresMouseEvents)
        #expect(overlayPanel.styleMask.contains(.nonactivatingPanel))
        #expect(overlayPanel.canBecomeKey == false)
        #expect(overlayPanel.canBecomeMain == false)

        #expect(NSApplication.shared.keyWindow?.windowNumber == keyWindowBefore)
        #expect(NSApplication.shared.mainWindow?.windowNumber == mainWindowBefore)
        #expect(NSWorkspace.shared.frontmostApplication?.processIdentifier == frontmostPIDBefore)

        presenter.remove()

        let afterRemove = presenter.diagnostics()
        #expect(afterRemove.isVisible == false)
        #expect(afterRemove.allocatedTextureBytes == 0)

        let overlayStillVisible = NSApplication.shared.windows
            .compactMap { $0 as? NSPanel }
            .contains(where: { $0.windowNumber == overlayPanel.windowNumber && $0.isVisible })
        #expect(overlayStillVisible == false)
    }

    private func primaryDisplayScaleFactor() -> CGFloat? {
        let mainDisplayID = CGMainDisplayID()
        let screenNumberKey = NSDeviceDescriptionKey("NSScreenNumber")

        if let mainMatch = NSScreen.screens.first(where: { screen in
            guard let number = screen.deviceDescription[screenNumberKey] as? NSNumber else { return false }
            return number.uint32Value == mainDisplayID
        }) {
            return mainMatch.backingScaleFactor
        }

        return NSScreen.main?.backingScaleFactor ?? NSScreen.screens.first?.backingScaleFactor
    }

    private func publishedBounds(windowNumber: Int) async -> CGRect? {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(2))
        repeat {
            if let frame = cgWindowBounds(windowNumber: windowNumber) { return frame }
            do { try await Task.sleep(for: .milliseconds(20)) }
            catch { return nil }
        } while clock.now < deadline
        return nil
    }

    private func cgWindowBounds(windowNumber: Int) -> CGRect? {
        guard let rows = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        for row in rows {
            guard let number = row[kCGWindowNumber as String] as? NSNumber,
                  number.intValue == windowNumber,
                  let bounds = row[kCGWindowBounds as String] as? NSDictionary,
                  let frame = CGRect(dictionaryRepresentation: bounds),
                  frame.width > 0,
                  frame.height > 0 else {
                continue
            }
            return frame
        }

        return nil
    }

    private func makeCGImage(from image: NSImage, sourcePath: String) throws -> CGImage {
        if let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let cgImage = bitmap.cgImage {
            return cgImage
        }
        throw OverlayPresenterAssertionError(message: "Unable to decode system icon from \(sourcePath)")
    }

    private func makeBGRAFrame(from image: CGImage, maxEdge: Int) throws -> BGRAPixelFrame {
        let width = max(1, min(image.width, maxEdge, 512))
        let height = max(1, min(image.height, maxEdge, 512))
        let bytesPerRow = width * 4
        var data = Data(count: bytesPerRow * height)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.union(
            CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        )

        let drawRect = CGRect(x: 0, y: 0, width: width, height: height)
        let contextCreated = data.withUnsafeMutableBytes { mutableBuffer -> Bool in
            guard let base = mutableBuffer.baseAddress,
                  let context = CGContext(
                    data: base,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo.rawValue
                  ) else {
                return false
            }
            context.interpolationQuality = .high
            context.draw(image, in: drawRect)
            return true
        }

        guard contextCreated else {
            throw OverlayPresenterAssertionError(message: "Unable to create BGRA CGContext for icon conversion")
        }

        return try BGRAPixelFrame(width: width, height: height, bytesPerRow: bytesPerRow, bytes: data)
    }
}

private struct OverlayPresenterAssertionError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
