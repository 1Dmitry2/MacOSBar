import HubSystemMonitor
import Testing

@Test func memoryUsedFractionBounds() {
    let snap = MemorySnapshot(
        totalBytes: 16_000_000_000,
        usedBytes: 8_000_000_000,
        freeBytes: 8_000_000_000,
        wiredBytes: 0,
        compressedBytes: 0,
        swapUsedBytes: 0,
        pressure: "Normal",
        history: []
    )
    #expect(snap.usedFraction == 0.5)
}
