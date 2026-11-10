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
    public init(
        compactSize: CGSize,
        expandedSize: CGSize,
        integratesNotch: Bool = false,
        notchBandHeight: CGFloat = 0,
        expandedBodyHeight: CGFloat? = nil
    ) {
        self.compactSize = compactSize
        self.expandedSize = expandedSize
        self.integratesNotch = integratesNotch
        self.notchBandHeight = notchBandHeight
        self.expandedBodyHeight = expandedBodyHeight ?? expandedSize.height
    }

    /// Bottom inset for compact indicators inside the housing band.
    public var compactContentBottomInset: CGFloat {
        integratesNotch ? max(2, min(5, notchBandHeight * 0.1)) : 6
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
