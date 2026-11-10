import AppKit
import SwiftUI

/// Forwards mouse hits only inside the live island bounds (top-aligned); rest passes to the menu bar.
final class IslandPassThroughHostingView<Content: View>: NSHostingView<Content> {
    var interactiveRect: CGRect = .zero

    required init(rootView: Content) {
        super.init(rootView: rootView)
        safeAreaRegions = []
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard interactiveRect.contains(point) else { return nil }
        return super.hitTest(point)
    }
}

enum IslandInteractiveRect {
    @MainActor
    static func compute(
        hostSize: CGSize,
        metrics: IslandLayoutMetrics,
        mode: IslandPresentationMode
    ) -> CGRect {
        let size = metrics.size(for: mode)
        let x = (hostSize.width - size.width) / 2
        let slop: CGFloat = 6
        let height = size.height + slop
        return CGRect(
            x: max(0, x - slop),
            y: 0,
            width: size.width + slop * 2,
            height: min(hostSize.height, height)
        )
    }
}
