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

    public static func preview(from config: AppConfiguration = .shared) -> IslandLayoutMetrics {
        let compactW = max(config.islandCompactWidth, 180)
        let compactH = config.islandCompactHeight
        let expandedW = min(config.islandExpandedWidth, 420)
        let expandedH = config.islandExpandedHeight
        return IslandLayoutMetrics(
            compactSize: CGSize(width: compactW, height: compactH),
            expandedSize: CGSize(width: expandedW, height: expandedH),
            integratesNotch: true
        )
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
