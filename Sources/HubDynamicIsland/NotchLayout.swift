import AppKit
import HubCore
import HubSettings

public struct NotchLayout {
    public var screen: NSScreen
    public var screenFrame: CGRect
    public var visibleFrame: CGRect
    public var hasNotch: Bool
    public var notchFrame: CGRect
    public var compactSize: CGSize
    public var expandedSize: CGSize
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
        let offset = verticalOffset ?? AppConfiguration.shared.islandVerticalOffset
        let config = AppConfiguration.shared

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
        let compactHeight = max(config.islandCompactHeight, safeBand > 0 ? safeBand + 4 : config.islandCompactHeight)
        let configuredCompact = config.islandCompactWidth
        let compactWidth: CGFloat
        if hasNotch {
            let notchWidth = max(notchRect.width, 1)
            compactWidth = max(notchWidth + 8, configuredCompact)
        } else {
            compactWidth = max(210, configuredCompact)
        }
        let expandedWidth = min(config.islandExpandedWidth, visible.width - 24)
        let expandedHeight = config.islandExpandedHeight

        let topAnchor: CGFloat
        if hasNotch {
            // Align with the physical screen top; compact height sits in the menu-bar band.
            topAnchor = frame.maxY + offset
        } else {
            topAnchor = visible.maxY - menuBand * 0.15 + offset
        }

        return NotchLayout(
            screen: screen,
            screenFrame: frame,
            visibleFrame: visible,
            hasNotch: hasNotch,
            notchFrame: notchRect,
            compactSize: CGSize(width: compactWidth, height: compactHeight),
            expandedSize: CGSize(width: expandedWidth, height: expandedHeight),
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
        let top = anchorY
        let maxTop = screenFrame.maxY
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

        let notchBottom = screenFrame.maxY - safeTop
        let notchRect = CGRect(
            x: centerX - notchWidth / 2,
            y: notchBottom,
            width: notchWidth,
            height: safeTop
        )
        return (true, notchRect, centerX)
    }
}
