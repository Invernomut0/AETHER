import AppKit
import Foundation
import Metal
import Testing
import AETHERShared
@testable import AETHERRendering

// Extend the existing serialized suite so real overlay tests cannot race the
// original preview tests' AppKit window inventory/focus assertions.
extension OverlayPresenterTests {
    // Analytical triangle geometry, not generated/synthetic image pixels.
    private var triangle: [OverlayVertex] {
        [OverlayVertex(position: SIMD2(-1, -1), textureCoordinate: SIMD2(0, 1)),
         OverlayVertex(position: SIMD2(1, -1), textureCoordinate: SIMD2(1, 1)),
         OverlayVertex(position: SIMD2(-1, 1), textureCoordinate: SIMD2(0, 0))]
    }

    @Test("Vertex ABI and bounded triangle-list validation")
    func vertexLayoutAndValidation() throws {
        #expect(MemoryLayout<OverlayVertex>.stride == 16)
        #expect(MemoryLayout<OverlayVertex>.offset(of: \.position) == 0)
        #expect(MemoryLayout<OverlayVertex>.offset(of: \.textureCoordinate) == 8)
        try MetalOverlayPresenter.validateEffectInput(vertices: triangle, opacity: 1, dissolve: 0)
        try MetalOverlayPresenter.validateEffectInput(vertices: triangle, opacity: 0, dissolve: 1)
        let maximumMesh = Array(repeating: triangle, count: 4096).flatMap { $0 }
        try MetalOverlayPresenter.validateEffectInput(vertices: maximumMesh, opacity: 0.5, dissolve: 0.5)
        for vertices in [[], Array(triangle.prefix(2)), maximumMesh + triangle] {
            #expect(throws: AetherError.self) {
                try MetalOverlayPresenter.validateEffectInput(vertices: vertices, opacity: 1, dissolve: 0)
            }
        }
        for value in [Float.nan, .infinity, -.infinity, -0.01, 1.01] {
            #expect(throws: AetherError.self) {
                try MetalOverlayPresenter.validateEffectInput(vertices: triangle, opacity: value, dissolve: 0)
            }
            #expect(throws: AetherError.self) {
                try MetalOverlayPresenter.validateEffectInput(vertices: triangle, opacity: 1, dissolve: value)
            }
        }
        for coordinate in [Float.nan, .infinity, -.infinity, -4.01, 4.01] {
            for axis in 0..<2 {
                var invalid = triangle
                invalid[0].position[axis] = coordinate
                #expect(throws: AetherError.self) {
                    try MetalOverlayPresenter.validateEffectInput(vertices: invalid, opacity: 1, dissolve: 0)
                }
            }
        }
        for coordinate in [Float.nan, .infinity, -.infinity, -0.01, 1.01] {
            for axis in 0..<2 {
                var invalid = triangle
                invalid[0].textureCoordinate[axis] = coordinate
                #expect(throws: AetherError.self) {
                    try MetalOverlayPresenter.validateEffectInput(vertices: invalid, opacity: 1, dissolve: 0)
                }
            }
        }
    }

    @Test("Unprepared rendering rejects without displaying a panel")
    func unpreparedRender() async throws {
        _ = NSApplication.shared
        let presenter = MetalOverlayPresenter()
        defer { presenter.remove() }
        await #expect(throws: AetherError.self) { try await presenter.renderEffect(vertices: triangle) }
        // The existing snapshot API still rejects zero; only effects accept it.
        let pixels = try systemIconPixels()
        await #expect(throws: AetherError.self) {
            try await presenter.present(pixels, frame: CGRect(x: 160, y: 180, width: 96, height: 96), relativeTo: 0)
        }
        #expect(presenter.diagnostics().isVisible == false)
        #expect(presenter.diagnostics().framesPresented == 0)
        #expect(presenter.diagnostics().allocatedTextureBytes == 0)
    }

    @Test("Effect preflight retains only real system-icon pixels and remains hidden")
    func hiddenPreflightAndInputFailures() throws {
        _ = NSApplication.shared
        let pixels = try systemIconPixels()
        let presenter = MetalOverlayPresenter()
        defer { presenter.remove() }
        let frame = CGRect(x: 160, y: 180, width: 96, height: 96)
        #expect(throws: AetherError.self) { try presenter.prepareEffect(pixels, frame: frame, relativeTo: -1) }
        for invalidFrame in [CGRect.zero, CGRect(x: 0, y: 0, width: -1, height: 96),
                             CGRect(x: CGFloat.nan, y: 0, width: 96, height: 96),
                             CGRect(x: 0, y: 0, width: CGFloat.infinity, height: 96),
                             CGRect(x: 0, y: 0, width: 16_385, height: 96),
                             CGRect(x: 16_384, y: 0, width: 96, height: 96)] {
            #expect(throws: AetherError.self) {
                try presenter.prepareEffect(pixels, frame: invalidFrame, relativeTo: 0)
            }
        }
        #expect(presenter.diagnostics().allocatedTextureBytes == 0)
        guard MTLCreateSystemDefaultDevice() != nil else { return }
        try presenter.prepareEffect(pixels, frame: frame, relativeTo: 0)
        #expect(presenter.diagnostics().isVisible == false)
        #expect(presenter.diagnostics().framesPresented == 0)
        #expect(presenter.diagnostics().allocatedTextureBytes == UInt64(pixels.width * pixels.height * 4))
        presenter.remove()
        #expect(presenter.diagnostics().allocatedTextureBytes == 0)
    }

    @Test("Real GPU renders successive effect frames then releases the cached snapshot")
    func realEffectFramesAndReuse() async throws {
        _ = NSApplication.shared
        guard MTLCreateSystemDefaultDevice() != nil else { return }
        let pixels = try systemIconPixels()
        let presenter = MetalOverlayPresenter()
        defer { presenter.remove() }
        let frame = CGRect(x: 160, y: 180, width: 96, height: 96)
        let mesh = triangle + [triangle[2], triangle[1],
                               OverlayVertex(position: SIMD2(1, 1), textureCoordinate: SIMD2(1, 0))]
        let keyBefore = NSApplication.shared.keyWindow?.windowNumber
        try presenter.prepareEffect(pixels, frame: frame, relativeTo: 0)
        try await presenter.renderEffect(vertices: mesh)
        let first = presenter.diagnostics()
        #expect(first.isVisible)
        #expect(first.framesPresented == 1)
        #expect(first.lastError == nil)
        try await presenter.renderEffect(vertices: mesh, opacity: 0.6, dissolve: 0.5)
        #expect(presenter.diagnostics().framesPresented == 2)
        #expect(presenter.diagnostics().allocatedTextureBytes == first.allocatedTextureBytes)
        try await presenter.renderEffect(vertices: mesh, dissolve: 1)
        #expect(presenter.diagnostics().framesPresented == 3)
        #expect(NSApplication.shared.keyWindow?.windowNumber == keyBefore)

        // Preparing again must hide an already visible overlay, not flash it.
        try presenter.prepareEffect(pixels, frame: frame, relativeTo: 0)
        #expect(presenter.diagnostics().isVisible == false)
        presenter.remove()
        presenter.remove()
        #expect(presenter.diagnostics().allocatedTextureBytes == 0)
        await #expect(throws: AetherError.self) { try await presenter.renderEffect(vertices: mesh) }
    }

    /// Decode the same installed Terminal icon source used by the existing suite.
    /// Pixel storage is filled by CoreGraphics from that image, not fabricated.
    private func systemIconPixels() throws -> BGRAPixelFrame {
        let icon = NSWorkspace.shared.icon(forFile: "/System/Applications/Utilities/Terminal.app")
        let tiff = try #require(icon.tiffRepresentation)
        let bitmap = try #require(NSBitmapImageRep(data: tiff))
        let image = try #require(bitmap.cgImage)
        let width = min(image.width, 64)
        let height = min(image.height, 64)
        let bytesPerRow = width * 4
        var data = Data(count: bytesPerRow * height)
        try data.withUnsafeMutableBytes { buffer in
            let base = try #require(buffer.baseAddress)
            let info = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
            let context = try #require(CGContext(data: base, width: width, height: height, bitsPerComponent: 8,
                                               bytesPerRow: bytesPerRow, space: CGColorSpaceCreateDeviceRGB(),
                                               bitmapInfo: info))
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return try BGRAPixelFrame(width: width, height: height, bytesPerRow: bytesPerRow, bytes: data)
    }
}