import CoreGraphics
import HubSettings

/// Sizing for in-window preview — same formulas as `NotchLayout` without screen anchoring.
public struct IslandLayoutMetrics: Equatable, Sendable {
    public var compactSize: CGSize
    public var expandedSize: CGSize

    public static func preview(from config: AppConfiguration = .shared) -> IslandLayoutMetrics {
        let compactW = max(config.islandCompactWidth, 180)
        let compactH = config.islandCompactHeight
        let expandedW = min(config.islandExpandedWidth, 420)
        let expandedH = config.islandExpandedHeight
        return IslandLayoutMetrics(
            compactSize: CGSize(width: compactW, height: compactH),
            expandedSize: CGSize(width: expandedW, height: expandedH)
        )
    }

    public func size(for mode: IslandPresentationMode) -> CGSize {
        mode.isExpandedLayout ? expandedSize : compactSize
    }
}
