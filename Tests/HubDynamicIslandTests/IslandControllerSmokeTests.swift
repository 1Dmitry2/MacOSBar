import AppKit
import HubDynamicIsland
import HubSettings
import Testing

/// Shared singleton state — entire suite is serialized (no cross-suite parallelism).
@Suite(.serialized)
@MainActor
struct IslandSerializedTests {
@Test func islandPanelStartToggleStop() {
    guard NSScreen.main != nil else { return }

    let island = DynamicIslandConfiguration.shared
    let priorEnabled = island.dynamicIslandEnabled
    defer {
        DynamicIslandController.shared.stop()
        island.dynamicIslandEnabled = priorEnabled
        island.applyPendingChanges()
    }

    island.dynamicIslandEnabled = true
    island.applyPendingChanges()
    DynamicIslandController.shared.startIfEnabled()
    #expect(DynamicIslandController.shared.isRunning)

    DynamicIslandController.shared.toggleExpanded()
    #expect(DynamicIslandController.shared.isExpanded)

    DynamicIslandController.shared.toggleExpanded()
    #expect(DynamicIslandController.shared.isExpanded == false)

    DynamicIslandController.shared.stop()
    IslandStateManager.shared.reset()
    #expect(DynamicIslandController.shared.isRunning == false)
}

@Test func previewLayoutSizesMatchConfig() {
    let island = DynamicIslandConfiguration.shared
    island.islandCompactHeight = 36
    island.islandExpandedHeight = 80
    let metrics = IslandLayoutMetrics.preview(from: island)
    #expect(metrics.compactSize.height == 36)
    #expect(metrics.expandedSize.height == metrics.compactSize.height + 80)
    #expect(metrics.size(for: .idle).height == metrics.compactSize.height)
    #expect(metrics.size(for: .notification).height == metrics.compactSize.height + 80)
}

    @Test func hoverPeekDoesNotCountAsUserExpanded() async {
        IslandStateManager.shared.reset()
        IslandStateManager.shared.hoverChanged(inside: true, hoverExpands: true)
        let delay = IslandAnimationPolicy.hoverExpandDelay
        try? await Task.sleep(for: .seconds(delay + 0.1))
        #expect(IslandStateManager.shared.phase == .hover)
        #expect(IslandStateManager.shared.isExpanded == false)
    }

    @Test func toggleExpandedFromHoverPinsOpen() async {
        IslandStateManager.shared.reset()
        IslandStateManager.shared.hoverChanged(inside: true, hoverExpands: true)
        try? await Task.sleep(for: .seconds(IslandAnimationPolicy.hoverExpandDelay + 0.1))
        IslandStateManager.shared.toggleExpanded()
        #expect(IslandStateManager.shared.phase == .expanded)
        #expect(IslandStateManager.shared.isExpanded)
    }

    @Test func hoverDelayUsesConfiguredTiming() async {
        IslandStateManager.shared.reset()
        let delay = IslandAnimationPolicy.hoverExpandDelay
        IslandStateManager.shared.hoverChanged(inside: true, hoverExpands: true)
        #expect(IslandStateManager.shared.phase == .idle)
        try? await Task.sleep(for: .seconds(max(0, delay - 0.05)))
        #expect(IslandStateManager.shared.phase == .idle)
        try? await Task.sleep(for: .seconds(0.1))
        #expect(IslandStateManager.shared.phase == .hover)
    }
}
