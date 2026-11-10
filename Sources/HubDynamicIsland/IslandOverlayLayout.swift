import AppKit
import CoreGraphics

/// Tight top-anchored host window — only wraps the island (not a full-screen invisible slab).
enum IslandOverlayLayout {
    static let canvasPadding: CGFloat = 20

    static func canvasSize(metrics: IslandLayoutMetrics, mode: IslandPresentationMode) -> CGSize {
        let island = metrics.size(for: mode)
        let width = min(max(island.width + canvasPadding * 2, 240), 920)
        let bottomPad = (metrics.integratesNotch && mode == .idle) ? 4 : canvasPadding
        let height = island.height + bottomPad
        return CGSize(width: width, height: max(height, 56))
    }

    static func topAnchoredFrame(
        on screen: NSScreen,
        metrics: IslandLayoutMetrics,
        mode: IslandPresentationMode,
        yOffset: CGFloat? = nil
    ) -> CGRect {
        let size = canvasSize(metrics: metrics, mode: mode)
        let lift = (metrics.integratesNotch && mode == .idle) ? metrics.compactFloatingWindowLift : 0
        let offset = yOffset ?? (1 + lift)
        let x = floor(screen.frame.midX - size.width / 2)
        let y = screen.frame.maxY - size.height + offset
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}
