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
