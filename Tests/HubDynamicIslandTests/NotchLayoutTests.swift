import AppKit
import HubDynamicIsland
import HubSettings
import Testing

@MainActor
@Test func expandedFrameKeepsBottomAnchor() {
    guard let screen = NSScreen.main else { return }
    let layout = NotchLayout.detect(screen: screen) ?? NotchLayout.detect()
    guard let layout else { return }
    let compact = layout.frame(expanded: false)
    let expanded = layout.frame(expanded: true)
    #expect(compact.origin.y == expanded.origin.y)
    #expect(expanded.size.height >= compact.size.height)
}

@Test func previewMetricsFollowConfiguration() {
    let config = AppConfiguration.shared
    config.islandCompactWidth = 250
    config.islandExpandedWidth = 400
    let metrics = IslandLayoutMetrics.preview(from: config)
    #expect(metrics.compactSize.width == 250)
    #expect(metrics.expandedSize.width == 400)
}

@Test func presentationModeExpansionFlag() {
    #expect(IslandPresentationMode.compact.isExpandedLayout == false)
    #expect(IslandPresentationMode.expanded.isExpandedLayout == true)
    #expect(IslandPresentationMode.notification.isExpandedLayout == true)
}
