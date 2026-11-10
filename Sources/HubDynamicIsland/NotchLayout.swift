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
    /// Bottom edge of the island in AppKit coordinates; expansion grows upward from here.
    public var bottomAnchorY: CGFloat

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

        var hasNotch = false
        var notchRect = CGRect.zero

        if #available(macOS 12.0, *) {
            let safeTop = screen.safeAreaInsets.top
            hasNotch = safeTop > 0
            if hasNotch {
                let notchWidth = max(180, min(260, visible.width * 0.14))
                let top = frame.maxY - safeTop
                notchRect = CGRect(x: frame.midX - notchWidth / 2, y: top, width: notchWidth, height: safeTop)
            }
        }

        let menuBand = max(frame.maxY - visible.maxY, 22)
        let compactHeight = config.islandCompactHeight
        let configuredCompact = config.islandCompactWidth
        let compactWidth = hasNotch ? max(notchRect.width + 28, configuredCompact) : max(210, configuredCompact)
        let expandedWidth = min(config.islandExpandedWidth, visible.width - 24)
        let expandedHeight = config.islandExpandedHeight

        let bottomAnchor: CGFloat
        if hasNotch {
            bottomAnchor = notchRect.minY
        } else {
            bottomAnchor = visible.maxY - menuBand * 0.15
        }

        return NotchLayout(
            screen: screen,
            screenFrame: frame,
            visibleFrame: visible,
            hasNotch: hasNotch,
            notchFrame: notchRect,
            compactSize: CGSize(width: compactWidth, height: compactHeight),
            expandedSize: CGSize(width: expandedWidth, height: expandedHeight),
            bottomAnchorY: bottomAnchor + offset
        )
    }

    public func frame(expanded: Bool) -> CGRect {
        let size = expanded ? expandedSize : compactSize
        let bottom = bottomAnchorY
        let maxTop = screenFrame.maxY - 2
        let maxHeight = max(24, maxTop - bottom)
        let height = min(size.height, maxHeight)
        let centerX = visibleFrame.midX
        let origin = CGPoint(x: centerX - size.width / 2, y: bottom)
        return CGRect(origin: origin, size: CGSize(width: size.width, height: height))
    }
}
