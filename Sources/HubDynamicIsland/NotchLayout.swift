import AppKit
import HubCore
import HubSettings

// MARK: - Notch geometry (AppKit global coords, y-up)
//
// On a notched built-in display (e.g. 14" MBP): `screen.frame.maxY` is the physical top;
// `visibleFrame.maxY` sits ~menuBarHeight lower (often safeAreaInsets.top + 1pt).
// Anchoring to visibleFrame.maxY or preserving a stale panel top within that band leaves
// the island visually below the camera housing. Use `frame.maxY` + auxiliaryTop* areas.

public struct NotchLayout {
    public var screen: NSScreen
    public var screenFrame: CGRect
    public var visibleFrame: CGRect
    public var hasNotch: Bool
    public var notchFrame: CGRect
    public var compactSize: CGSize
    public var expandedSize: CGSize
    /// Menu-bar / camera housing band (`safeAreaInsets.top` on notched built-in displays).
    public var notchBandHeight: CGFloat
    /// Expanded content area below the housing band (user setting).
    public var expandedBodyHeight: CGFloat
    /// Horizontal center of the notch (or visible frame when no notch).
    public var islandCenterX: CGFloat
    /// Top edge of the island in AppKit coordinates; expansion grows downward from here.
    public var topAnchorY: CGFloat

    /// Deprecated alias for callers that referenced bottom anchoring.
    public var bottomAnchorY: CGFloat {
        let height = compactSize.height
        return topAnchorY - height
    }

    @MainActor
    public static func detect(
        screen: NSScreen? = nil,
        verticalOffset: CGFloat? = nil
    ) -> NotchLayout? {
        guard let screen = screen ?? HubDisplayResolver.resolvedIslandScreen() else { return nil }

        let frame = screen.frame
        let visible = screen.visibleFrame
        let runtime = DynamicIslandConfiguration.shared.runtimeSnapshot
        let offset = verticalOffset ?? runtime.verticalOffset

        let geometry: (hasNotch: Bool, notchFrame: CGRect, centerX: CGFloat)
        if #available(macOS 12.0, *) {
            geometry = notchGeometry(on: screen, screenFrame: frame)
        } else {
            geometry = (false, .zero, visible.midX)
        }
        let hasNotch = geometry.hasNotch
        let notchRect = geometry.notchFrame
        let centerX = geometry.centerX

        let menuBand = max(frame.maxY - visible.maxY, 22)
        let safeBand = hasNotch ? max(screen.safeAreaInsets.top, 0) : 0
        let compactHeight: CGFloat = hasNotch ? safeBand : runtime.compactHeight
        let configuredCompact = runtime.compactWidth
        let compactWidth: CGFloat
        if hasNotch {
            // Match physical cutout width from auxiliary areas — no padding fudge factor.
            compactWidth = max(notchRect.width, 1)
        } else {
            compactWidth = max(210, configuredCompact)
        }
        let expandedWidth = min(runtime.expandedWidth, visible.width - 24)
        let expandedBodyHeight = runtime.expandedHeight
        let expandedHeight = hasNotch ? safeBand + expandedBodyHeight : expandedBodyHeight

        let physicalTopY = frame.maxY
        let topAnchor: CGFloat = hasNotch
            ? physicalTopY + offset
            : visible.maxY - menuBand * 0.15 + offset

        return NotchLayout(
            screen: screen,
            screenFrame: frame,
            visibleFrame: visible,
            hasNotch: hasNotch,
            notchFrame: notchRect,
            compactSize: CGSize(width: compactWidth, height: compactHeight),
            expandedSize: CGSize(width: expandedWidth, height: expandedHeight),
            notchBandHeight: safeBand,
            expandedBodyHeight: expandedBodyHeight,
            islandCenterX: centerX,
            topAnchorY: topAnchor
        )
    }

    /// Host window bounds (expanded height); SwiftUI animates the visible island inside this top-anchored frame.
    public func panelFrame(topAnchorY anchorY: CGFloat? = nil) -> CGRect {
        frame(expanded: true, topAnchorY: anchorY ?? topAnchorY)
    }

    public func frame(expanded: Bool) -> CGRect {
        frame(expanded: expanded, topAnchorY: topAnchorY)
    }

  /// Builds a window frame with a fixed top edge so expand/collapse only changes height downward.
    public func frame(expanded: Bool, topAnchorY anchorY: CGFloat) -> CGRect {
        let size = expanded ? expandedSize : compactSize
        let top = min(anchorY, screenFrame.maxY)
        let availableBelow = max(24, top - screenFrame.minY)
        let height = min(size.height, availableBelow)
        let centerX = islandCenterX
        let origin = CGPoint(x: centerX - size.width / 2, y: top - height)
        let clampedX = max(screenFrame.minX + 8, min(origin.x, screenFrame.maxX - size.width - 8))
        return CGRect(origin: CGPoint(x: clampedX, y: origin.y), size: CGSize(width: size.width, height: height))
    }

    @available(macOS 12.0, *)
    private static func notchGeometry(on screen: NSScreen, screenFrame: CGRect) -> (
        hasNotch: Bool,
        notchFrame: CGRect,
        centerX: CGFloat
    ) {
        let safeTop = screen.safeAreaInsets.top
        guard safeTop > 0 else {
            return (false, .zero, screen.visibleFrame.midX)
        }

        let fallbackWidth = max(180, min(260, screenFrame.width * 0.14))
        var notchWidth = fallbackWidth
        var centerX = screenFrame.midX

        if let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea,
           !left.isNull,
           !right.isNull,
           right.minX > left.maxX {
            notchWidth = right.minX - left.maxX
            centerX = (left.maxX + right.minX) / 2
        }

        let notchTopY = screenFrame.maxY
        let notchRect = CGRect(
            x: centerX - notchWidth / 2,
            y: notchTopY - safeTop,
            width: notchWidth,
            height: safeTop
        )
        return (true, notchRect, centerX)
    }
}
