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
    #expect(compact.maxY == expanded.maxY)
    #expect(expanded.size.height >= compact.size.height)
}

@MainActor
@Test func expandedFrameStaysHorizontallyCentered() {
    guard let screen = NSScreen.main else { return }
    let layout = NotchLayout.detect(screen: screen) ?? NotchLayout.detect()
    guard let layout else { return }
    let compact = layout.frame(expanded: false)
    let expanded = layout.frame(expanded: true)
    let compactMidX = compact.midX
    let expandedMidX = expanded.midX
    let centerX = layout.islandCenterX
    #expect(abs(compactMidX - centerX) < 1)
    #expect(abs(expandedMidX - centerX) < 1)
    #expect(abs(compactMidX - expandedMidX) < 1)
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
    #expect(IslandPresentationMode.idle.isExpandedLayout == false)
    #expect(IslandPresentationMode.hover.isExpandedLayout == false)
    #expect(IslandPresentationMode.expanded.isExpandedLayout == true)
    #expect(IslandPresentationMode.notification.isExpandedLayout == true)
}
