import AppKit

public struct NotchLayout {
    public var screenFrame: CGRect
    public var hasNotch: Bool
    public var notchFrame: CGRect
    public var islandOrigin: CGPoint
    public var compactSize: CGSize
    public var expandedSize: CGSize

    @MainActor
    public static func detect() -> NotchLayout? {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return nil }
        let frame = screen.frame
        var hasNotch = false
        var notchRect = CGRect.zero
        if #available(macOS 12.0, *) {
            let extra = screen.safeAreaInsets
            hasNotch = extra.top > 0
            if hasNotch {
                let notchWidth: CGFloat = 220
                let top = frame.maxY - extra.top
                notchRect = CGRect(x: frame.midX - notchWidth / 2, y: top, width: notchWidth, height: extra.top)
            }
        }
        let compact = CGSize(width: hasNotch ? 240 : 200, height: 36)
        let expanded = CGSize(width: 420, height: 120)
        let originY = hasNotch ? notchRect.minY - 4 : frame.maxY - 48
        let origin = CGPoint(x: frame.midX - compact.width / 2, y: originY)
        return NotchLayout(
            screenFrame: frame,
            hasNotch: hasNotch,
            notchFrame: notchRect,
            islandOrigin: origin,
            compactSize: compact,
            expandedSize: expanded
        )
    }
}
