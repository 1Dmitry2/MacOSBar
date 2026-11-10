import Foundation
import Testing
@testable import HubDynamicIsland

@Test func systemEventSnapshotSuggestsMicPresentation() {
    let snapshot = SystemEventSnapshot(
        microphoneActive: true,
        cameraActive: false,
        activities: [
            IslandActivity(id: "mic", kind: .microphone, title: "Mic", systemImage: "mic.fill"),
        ],
        transient: nil
    )
    #expect(snapshot.suggestedPresentation == .mic)
}

@Test
@MainActor
func dominantCompactActivityPrefersMediaOverHeadphones() {
    let state = DynamicIslandStateManager.shared
    state.clearSystemActivities()
    state.upsertPersistent(
        IslandActivity(id: "audio", kind: .audioDevice, title: "External Headphones", systemImage: "headphones"),
        clearID: nil
    )
    state.upsertPersistent(
        IslandActivity(id: "media", kind: .media, title: "DO U STILL LOVE ME?", systemImage: "play.fill"),
        clearID: nil
    )
  #expect(state.dominantCompactActivity(excludingMedia: false)?.kind == .media)
    #expect(state.dominantCompactActivity(excludingMedia: true)?.kind == .audioDevice)
}

@Test func systemEventSnapshotSuggestsMultiple() {
    let snapshot = SystemEventSnapshot(
        microphoneActive: true,
        cameraActive: true,
        activities: [
            IslandActivity(id: "mic", kind: .microphone, title: "Mic", systemImage: "mic.fill"),
            IslandActivity(id: "cam", kind: .camera, title: "Cam", systemImage: "video.fill"),
        ],
        transient: nil
    )
    #expect(snapshot.suggestedPresentation == .multiple)
}
