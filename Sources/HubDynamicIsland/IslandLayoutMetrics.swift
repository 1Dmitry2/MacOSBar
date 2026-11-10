import CoreGraphics
import HubSettings

/// Sizing for in-window preview — same formulas as `NotchLayout` without screen anchoring.
public struct IslandLayoutMetrics: Equatable, Sendable {
    public var compactSize: CGSize
    public var expandedSize: CGSize
    public var integratesNotch: Bool

    public init(compactSize: CGSize, expandedSize: CGSize, integratesNotch: Bool = false) {
        self.compactSize = compactSize
        self.expandedSize = expandedSize
        self.integratesNotch = integratesNotch
    }

    public static func preview(from snapshot: DynamicIslandSettingsSnapshot) -> IslandLayoutMetrics {
        let compactW = max(snapshot.compactWidth, 180)
        let compactH = snapshot.compactHeight
        let expandedW = min(snapshot.expandedWidth, 420)
        let expandedH = snapshot.expandedHeight
        return IslandLayoutMetrics(
            compactSize: CGSize(width: compactW, height: compactH),
            expandedSize: CGSize(width: expandedW, height: expandedH),
            integratesNotch: true
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
            return CGSize(
                width: compactSize.width + (expandedSize.width - compactSize.width) * 0.38,
                height: compactSize.height + (expandedSize.height - compactSize.height) * 0.45
            )
        case .expanded, .mic, .camera, .headphones, .music, .notification, .multiple:
            return expandedSize
        }
    }
}
