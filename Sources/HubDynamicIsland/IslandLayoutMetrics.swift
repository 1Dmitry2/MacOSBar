import CoreGraphics
import HubSettings

/// Sizing for in-window preview — same formulas as `NotchLayout` without screen anchoring.
public struct IslandLayoutMetrics: Equatable, Sendable {
    public static let nookDockHeight: CGFloat = 42
    public static let nookDockSpacing: CGFloat = 12
    public static let compactFloatingTopSeam: CGFloat = 0
    public static let compactFloatingBottomInset: CGFloat = 0
    public static let compactFloatingPillHeight: CGFloat = 34
    /// Slide pill up under the camera housing (removes wallpaper band above capsule).
    public static let compactFloatingNotchTuck: CGFloat = 30

    public var compactSize: CGSize
    public var compactPillWidth: CGFloat
    public var expandedSize: CGSize
    public var integratesNotch: Bool
    /// Height of the physical menu-bar / notch band; compact widgets sit on its bottom edge.
    public var notchBandHeight: CGFloat
    /// Expanded card height excluding `notchBandHeight`.
    public var expandedBodyHeight: CGFloat
    /// Menu-bar strip height (readable area below camera housing).
    public var menuBarBandHeight: CGFloat
    public init(
        compactSize: CGSize,
        expandedSize: CGSize,
        compactPillWidth: CGFloat? = nil,
        integratesNotch: Bool = false,
        notchBandHeight: CGFloat = 0,
        expandedBodyHeight: CGFloat? = nil,
        menuBarBandHeight: CGFloat = 0
    ) {
        self.compactSize = compactSize
        self.expandedSize = expandedSize
        self.compactPillWidth = compactPillWidth ?? compactSize.width
        self.integratesNotch = integratesNotch
        self.notchBandHeight = notchBandHeight
        self.expandedBodyHeight = expandedBodyHeight ?? expandedSize.height
        self.menuBarBandHeight = menuBarBandHeight
    }

    /// Camera / housing band — no readable UI in the center column.
    public var occlusionReserveHeight: CGFloat {
        guard integratesNotch else { return 0 }
        return notchBandHeight
    }

    /// Height of the strip below the housing band where compact labels stay visible.
    public var compactReadableStripHeight: CGFloat {
        guard integratesNotch else { return compactSize.height }
        return max(18, compactSize.height - notchBandHeight)
    }

    /// Legacy bottom inset; prefer top reserve + readable strip layout.
    public var compactContentBottomInset: CGFloat {
        guard integratesNotch else { return 6 }
        return 4
    }

    /// Pill tucked under the notch lip (NotchNook-style), not floating in the menu strip.
    public var compactFloatingPillTopInset: CGFloat {
        guard integratesNotch else { return 0 }
        let tucked = occlusionReserveHeight - Self.compactFloatingNotchTuck + Self.compactFloatingTopSeam
        return max(0, tucked)
    }

    public var compactFloatingWindowLift: CGFloat {
        guard integratesNotch else { return 0 }
        return min(8, compactFloatingPillTopInset + 2)
    }

    public var compactFloatingHostHeight: CGFloat {
        guard integratesNotch else { return compactSize.height }
        return compactFloatingPillTopInset + Self.compactFloatingPillHeight + Self.compactFloatingBottomInset
    }

    public var compactFloatingPillSize: CGSize {
        CGSize(width: compactPillWidth, height: Self.compactFloatingPillHeight)
    }

    public static func preview(from snapshot: DynamicIslandSettingsSnapshot) -> IslandLayoutMetrics {
        let compactW = max(snapshot.compactWidth, 180)
        let compactH = snapshot.compactHeight
        let expandedW = min(snapshot.expandedWidth, 920)
        let expandedH = snapshot.expandedHeight
        return IslandLayoutMetrics(
            compactSize: CGSize(width: compactW, height: compactH),
            expandedSize: CGSize(width: expandedW, height: compactH + expandedH),
            compactPillWidth: max(compactW, 268),
            integratesNotch: true,
            notchBandHeight: compactH,
            expandedBodyHeight: expandedH
        )
    }

    public static func preview(from config: DynamicIslandConfiguration = .shared) -> IslandLayoutMetrics {
        preview(from: config.draftSnapshot)
    }

    public static func runtime(from config: DynamicIslandConfiguration = .shared) -> IslandLayoutMetrics {
        preview(from: config.runtimeSnapshot)
    }

    public func cardSize(for mode: IslandPresentationMode) -> CGSize {
        switch mode {
        case .idle:
            return compactSize
        case .hover, .expanded, .mic, .camera, .headphones, .music, .notification, .multiple:
            return expandedSize
        }
    }

    public func size(for mode: IslandPresentationMode) -> CGSize {
        let card = cardSize(for: mode)
        if integratesNotch, mode == .idle {
            return CGSize(
                width: max(card.width, compactPillWidth),
                height: compactFloatingHostHeight
            )
        }
        guard mode.usesNookDock else { return card }
        return CGSize(
            width: card.width,
            height: card.height + Self.nookDockSpacing + Self.nookDockHeight
        )
    }

    /// Visible, clickable footprint — compact idle is only the floating pill below the notch.
    public func interactiveFootprint(for mode: IslandPresentationMode) -> (size: CGSize, topInset: CGFloat) {
        if integratesNotch, mode == .idle {
            return (compactFloatingPillSize, compactFloatingPillTopInset)
        }
        return (size(for: mode), 0)
    }

    public func panelCardSize(for mode: IslandPresentationMode) -> CGSize {
        cardSize(for: mode)
    }
}

extension IslandPresentationMode {
    /// Expanded Nook card + dock pill (hover uses the same footprint as click-expand).
    public var usesNookDock: Bool {
        switch self {
        case .hover, .expanded, .music:
            return true
        case .idle, .mic, .camera, .headphones, .notification, .multiple:
            return false
        }
    }
}
