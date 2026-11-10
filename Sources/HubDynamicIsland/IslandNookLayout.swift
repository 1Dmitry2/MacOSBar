import SwiftUI

enum IslandNookLayout {
    static let panelHorizontalPadding: CGFloat = 16
    static let panelTopPadding: CGFloat = 10
    static let panelBottomPadding: CGFloat = 8
    static let sectionSpacing: CGFloat = 12
    static let tileSpacing: CGFloat = 10
    static let tileCornerRadius: CGFloat = 12
    static let tileMinHeight: CGFloat = 88
    static let metricGridColumns = 3
}

struct IslandNookMetricTile<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, minHeight: IslandNookLayout.tileMinHeight, alignment: .topLeading)
            .padding(10)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: IslandNookLayout.tileCornerRadius, style: .continuous))
    }
}
