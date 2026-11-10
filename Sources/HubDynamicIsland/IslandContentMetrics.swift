import SwiftUI

/// Derived sizing from live island card body so panels scale with width/height sliders.
struct IslandContentMetrics: Equatable {
    let bodyWidth: CGFloat
    let bodyHeight: CGFloat

    var scale: CGFloat {
        min(1, max(0.7, bodyWidth / 420))
    }

    var isNarrow: Bool { bodyWidth < 360 }
    var isShort: Bool { bodyHeight < 210 }

    var sectionSpacing: CGFloat { isShort ? 8 : 12 }
    var horizontalPadding: CGFloat { isNarrow ? 12 : 16 }
    var albumArtSize: CGFloat { (isNarrow ? 48 : 64) * scale }
    var titleFont: Font { isNarrow ? .caption.weight(.semibold) : .subheadline.weight(.semibold) }
    var artistFont: Font { .caption2 }
    var titleLineLimit: Int { isNarrow ? 1 : 2 }
    var metricColumns: Int { isNarrow ? 2 : 3 }
    var focusTimeFontSize: CGFloat { isShort ? 28 : 36 }
    var transportSpacing: CGFloat { isNarrow ? 12 : 18 }
    var scrollableMaxHeight: CGFloat { max(120, bodyHeight - 8) }

    static let fallback = IslandContentMetrics(bodyWidth: 420, bodyHeight: 240)
}

private struct IslandContentMetricsKey: EnvironmentKey {
    static let defaultValue = IslandContentMetrics.fallback
}

extension EnvironmentValues {
    var islandContentMetrics: IslandContentMetrics {
        get { self[IslandContentMetricsKey.self] }
        set { self[IslandContentMetricsKey.self] = newValue }
    }
}
