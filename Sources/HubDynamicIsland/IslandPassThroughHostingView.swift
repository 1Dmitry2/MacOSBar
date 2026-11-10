import AppKit
import SwiftUI

/// Forwards mouse hits only inside the live island bounds (top-aligned); rest passes to the menu bar.
final class IslandPassThroughHostingView<Content: View>: NSHostingView<Content> {
    var interactiveRect: CGRect = .zero {
        didSet {
            updatePointerTrackingAreas()
            reconcilePointerHover()
        }
    }

    var onPointerHover: ((Bool) -> Void)?
    var onIslandClick: (() -> Void)?

    private var trackingAreasInstalled: [NSTrackingArea] = []
    private var clickDownPoint: NSPoint?
    private var pointerInside = false

    required init(rootView: Content) {
        super.init(rootView: rootView)
        safeAreaRegions = []
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard interactiveRect.contains(point) else { return nil }
        if let hit = super.hitTest(point) { return hit }
        return self
    }

    override func mouseDown(with event: NSEvent) {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        clickDownPoint = convert(event.locationInWindow, from: nil)
        super.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        defer {
            clickDownPoint = nil
            super.mouseUp(with: event)
        }
        guard event.buttonNumber == 0, interactiveRect.contains(point) else { return }
        if let down = clickDownPoint {
            let dx = point.x - down.x
            let dy = point.y - down.y
            guard (dx * dx + dy * dy) < 36 else { return }
        }
        onIslandClick?()
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        emitHoverIfNeeded(for: convert(event.locationInWindow, from: nil))
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        updatePointerTrackingAreas()
    }

    private func updatePointerTrackingAreas() {
        for area in trackingAreasInstalled {
            removeTrackingArea(area)
        }
        trackingAreasInstalled.removeAll()

        guard !interactiveRect.isNull, interactiveRect.width > 1, interactiveRect.height > 1 else { return }

        let area = NSTrackingArea(
            rect: interactiveRect,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeInActiveApp, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingAreasInstalled.append(area)
    }

    override func mouseEntered(with event: NSEvent) {
        emitHoverIfNeeded(for: convert(event.locationInWindow, from: nil))
    }

    override func mouseExited(with event: NSEvent) {
        emitHoverIfNeeded(for: nil)
    }

    func reconcilePointerHover() {
        guard let window else { return }
        let point = convert(window.mouseLocationOutsideOfEventStream, from: nil)
        emitHoverIfNeeded(for: point)
    }

    private func emitHoverIfNeeded(for point: NSPoint?) {
        let inside: Bool
        if let point {
            inside = interactiveRect.contains(point)
        } else {
            inside = false
        }
        guard inside != pointerInside else { return }
        pointerInside = inside
        onPointerHover?(inside)
    }
}

enum IslandInteractiveRect {
    @MainActor
    static func compute(
        hostSize: CGSize,
        metrics: IslandLayoutMetrics,
        mode: IslandPresentationMode,
        isFlipped: Bool
    ) -> CGRect {
        let footprint = metrics.interactiveFootprint(for: mode)
        let slop: CGFloat = mode.usesNookDock ? 18 : 10
        let width = footprint.size.width + slop * 2
        let height = footprint.size.height + slop * 2
        let x = max(0, (hostSize.width - width) / 2)
        let y: CGFloat
        if isFlipped {
            y = max(0, footprint.topInset - slop)
        } else {
            y = max(0, hostSize.height - footprint.topInset - footprint.size.height - slop)
        }
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
