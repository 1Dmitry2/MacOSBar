import AppKit
import HubDynamicIsland
import HubSettings
import SwiftUI
import Testing

@MainActor
@Test func notchedDisplayTopAnchorMatchesPhysicalTop() {
    guard let screen = NSScreen.screens.first(where: {
        $0.safeAreaInsets.top > 0
    }) ?? NSScreen.main else { return }
    let layout = NotchLayout.detect(screen: screen)
    guard let layout, layout.hasNotch else { return }
    #expect(abs(layout.topAnchorY - layout.screenFrame.maxY) < 0.5)
    #expect(layout.compactSize.height > layout.screen.safeAreaInsets.top)
    #expect(layout.expandedSize.height >= layout.notchBandHeight + layout.expandedBodyHeight)
    #expect(abs(layout.frame(expanded: false).maxY - layout.topAnchorY) < 0.5)
}

@MainActor
@Test func expandedFrameKeepsTopAnchor() {
    guard let screen = NSScreen.main else { return }
    let layout = NotchLayout.detect(screen: screen) ?? NotchLayout.detect()
    guard let layout else { return }
    let compact = layout.frame(expanded: false)
    let expanded = layout.frame(expanded: true)
    #expect(abs(compact.maxY - expanded.maxY) < 0.5)
    #expect(abs(compact.maxY - layout.topAnchorY) < 0.5)
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

@Test func chromeColorsFollowSnapshot() {
    var snap = DynamicIslandSettingsSnapshot.defaults
    snap.chromeRed = 0.1
    snap.accentRed = 0.9
    snap.foregroundBlue = 0.8
    let colors = IslandChromeColors.from(snapshot: snap)
    #expect(colors.background == Color(red: 0.1, green: 0, blue: 0))
    #expect(colors.accent == Color(red: 0.9, green: 0.45, blue: 1.0))
}

@Test func previewMetricsFollowConfiguration() {
    let island = DynamicIslandConfiguration.shared
    island.islandCompactWidth = 250
    island.islandExpandedWidth = 400
    let metrics = IslandLayoutMetrics.preview(from: island)
    #expect(metrics.compactSize.width == 250)
    #expect(metrics.expandedSize.width == 400)
}

@Test func presentationModeExpansionFlag() {
    #expect(IslandPresentationMode.idle.isExpandedLayout == false)
    #expect(IslandPresentationMode.hover.isExpandedLayout == true)
    #expect(IslandPresentationMode.expanded.isExpandedLayout == true)
    #expect(IslandPresentationMode.notification.isExpandedLayout == true)
}
