import AppKit
import HubDynamicIsland
import HubSettings
import Testing

@MainActor
@Test func islandPanelStartToggleStop() {
    guard NSScreen.main != nil else { return }

    let config = AppConfiguration.shared
    let priorEnabled = config.dynamicIslandEnabled
    defer {
        DynamicIslandController.shared.stop()
        config.dynamicIslandEnabled = priorEnabled
    }

    config.dynamicIslandEnabled = true
    DynamicIslandController.shared.startIfEnabled()
    #expect(DynamicIslandController.shared.isRunning)

    DynamicIslandController.shared.toggleExpanded()
    #expect(DynamicIslandController.shared.isExpanded)

    DynamicIslandController.shared.toggleExpanded()
    #expect(DynamicIslandController.shared.isExpanded == false)

    DynamicIslandController.shared.stop()
    #expect(DynamicIslandController.shared.isRunning == false)
}

@MainActor
@Test func previewLayoutSizesMatchConfig() {
    let config = AppConfiguration.shared
    config.islandCompactHeight = 36
    config.islandExpandedHeight = 80
    let metrics = IslandLayoutMetrics.preview(from: config)
    #expect(metrics.compactSize.height == 36)
    #expect(metrics.expandedSize.height == 80)
    #expect(metrics.size(for: .idle).height == 36)
    #expect(metrics.size(for: .notification).height == 80)
}
