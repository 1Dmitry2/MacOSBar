import CoreGraphics
import HubSettings

/// Sizing for in-window preview — same formulas as `NotchLayout` without screen anchoring.
public struct IslandLayoutMetrics: Equatable, Sendable {
    public var compactSize: CGSize
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
        integratesNotch: Bool = false,
        notchBandHeight: CGFloat = 0,
        expandedBodyHeight: CGFloat? = nil,
        menuBarBandHeight: CGFloat = 0
    ) {
        self.compactSize = compactSize
        self.expandedSize = expandedSize
        self.integratesNotch = integratesNotch
        self.notchBandHeight = notchBandHeight
        self.expandedBodyHeight = expandedBodyHeight ?? expandedSize.height
        self.menuBarBandHeight = menuBarBandHeight
    }

    /// Housing band reserved for camera occlusion; readable UI starts below this.
    public var occlusionReserveHeight: CGFloat {
        guard integratesNotch else { return 0 }
        return max(notchBandHeight, menuBarBandHeight)
    }

    /// Bottom inset for compact indicators inside the housing band.
    public var compactContentBottomInset: CGFloat {
        // Keep glyphs in the visible menu strip at the bottom of the housing band (not under the camera lip).
        guard integratesNotch else { return 6 }
        let reserve = occlusionReserveHeight
        return max(10, min(18, reserve * 0.45))
    }

    public static func preview(from snapshot: DynamicIslandSettingsSnapshot) -> IslandLayoutMetrics {
        let compactW = max(snapshot.compactWidth, 180)
        let compactH = snapshot.compactHeight
        let expandedW = min(snapshot.expandedWidth, 420)
        let expandedH = snapshot.expandedHeight
        return IslandLayoutMetrics(
            compactSize: CGSize(width: compactW, height: compactH),
            expandedSize: CGSize(width: expandedW, height: compactH + expandedH),
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

    public func size(for mode: IslandPresentationMode) -> CGSize {
        switch mode {
        case .idle:
            return compactSize
        case .hover:
            return compactSize
        case .expanded, .mic, .camera, .headphones, .music, .notification, .multiple:
            return expandedSize
        }
    }
}
