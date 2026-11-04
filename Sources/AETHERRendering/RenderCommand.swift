import Foundation
import AETHERShared

public enum RenderCommand: Sendable {
    case prepareOverlay(window: RuntimeWindowHandle, frame: CodableRect)
    case updateEffect(window: RuntimeWindowHandle, effect: EffectID, progress: Double)
    case removeOverlay(window: RuntimeWindowHandle)
}
