import AppKit
import HubCore
import HubSettings

public struct NotchLayout {
    public var screen: NSScreen
    public var screenFrame: CGRect
    public var visibleFrame: CGRect
    public var hasNotch: Bool
    public var notchFrame: CGRect
    public var islandOrigin: CGPoint
    public var compactSize: CGSize
    public var expandedSize: CGSize

    @MainActor
    public static func detect(
        screen: NSScreen? = nil,
        verticalOffset: CGFloat? = nil
    ) -> NotchLayout? {
        guard let screen = screen ?? HubDisplayResolver.resolvedIslandScreen() else { return nil }

        let frame = screen.frame
        let visible = screen.visibleFrame
        var hasNotch = false
        var notchRect = CGRect.zero

        if #available(macOS 12.0, *) {
            let extra = screen.safeAreaInsets
            hasNotch = extra.top > 0
            if hasNotch {
                let notchWidth: CGFloat = max(200, min(260, visible.width * 0.16))
                let top = frame.maxY - extra.top
                notchRect = CGRect(x: frame.midX - notchWidth / 2, y: top, width: notchWidth, height: extra.top)
            }
        }

        let compact = CGSize(width: hasNotch ? 250 : 210, height: 38)
        let expanded = CGSize(width: min(460, visible.width - 32), height: 124)
        let offset = verticalOffset ?? AppConfiguration.shared.islandVerticalOffset

        let originY: CGFloat
        if hasNotch {
            originY = notchRect.minY - compact.height + 6 + offset
        } else {
            originY = visible.maxY - compact.height - 10 + offset
        }

        let origin = CGPoint(x: frame.midX - compact.width / 2, y: originY)

        return NotchLayout(
            screen: screen,
            screenFrame: frame,
            visibleFrame: visible,
            hasNotch: hasNotch,
            notchFrame: notchRect,
            islandOrigin: origin,
            compactSize: compact,
            expandedSize: expanded
        )
    }

    public func frame(expanded: Bool) -> CGRect {
        let size = expanded ? expandedSize : compactSize
        var origin = islandOrigin
        origin.x = screenFrame.midX - size.width / 2
        if hasNotch {
            origin.y = notchFrame.minY - size.height + 6 + (AppConfiguration.shared.islandVerticalOffset)
        } else {
            origin.y = visibleFrame.maxY - size.height - 10 + AppConfiguration.shared.islandVerticalOffset
        }
        return CGRect(origin: origin, size: size)
    }
}
