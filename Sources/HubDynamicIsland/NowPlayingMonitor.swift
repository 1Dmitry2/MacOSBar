import Foundation
import MediaPlayer
import Observation

@MainActor
@Observable
public final class NowPlayingMonitor: @unchecked Sendable {
    public static let shared = NowPlayingMonitor()

    public private(set) var title: String?
    public private(set) var artist: String?
    public private(set) var isPlaying = false

    private var timer: Timer?
    private var remoteObserverInstalled = false

    private init() {
        installRemoteObserverIfNeeded()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    private func installRemoteObserverIfNeeded() {
        guard !remoteObserverInstalled else { return }
        remoteObserverInstalled = true
        SystemNowPlayingReader.registerForUpdates { [weak self] in
            Task { @MainActor in self?.refresh() }
        }
    }

    public func refresh() {
        let snap = SystemNowPlayingReader.current()
        let wasPlaying = isPlaying
        title = snap.title
        artist = snap.artist
        isPlaying = snap.isPlaying
        if wasPlaying != isPlaying || snap.title != nil {
            NotificationCenter.default.post(name: .islandNowPlayingDidChange, object: nil)
        }
    }
}
