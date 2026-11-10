import Foundation
import HubDynamicIsland
import Testing

@Test @MainActor func focusTimerCountsDown() async throws {
    let store = IslandNookStore.shared
    store.stopFocusTimer()
    store.focusDurationMinutes = 10
    store.startFocusTimer()
    #expect(store.focusRunning)
    #expect(store.focusRemainingSeconds == 600)
    try await Task.sleep(for: .seconds(2.2))
    #expect(store.focusRunning)
    let remaining = store.focusRemainingSeconds ?? -1
    #expect(remaining <= 598, "expected countdown, got \(remaining)")
    #expect(remaining >= 596)
    store.stopFocusTimer()
    #expect(!store.focusRunning)
}
