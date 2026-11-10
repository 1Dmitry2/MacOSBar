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
    private var refreshInFlight = false
    private var lastSnapshot = SystemNowPlayingReader.Snapshot.empty

    private init() {
        installRemoteObserverIfNeeded()
        enqueueRefresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.enqueueRefresh()
        }
    }

    private func installRemoteObserverIfNeeded() {
        guard !remoteObserverInstalled else { return }
        remoteObserverInstalled = true
        SystemNowPlayingReader.registerForUpdates { [weak self] in
            Task { @MainActor in self?.enqueueRefresh() }
        }
    }

    public func refresh() {
        enqueueRefresh()
    }

    private func enqueueRefresh() {
        Task { await performRefresh() }
    }

    private func performRefresh() async {
        guard !refreshInFlight else { return }
        refreshInFlight = true
        defer { refreshInFlight = false }

        let snap = await Task.detached(priority: .utility) {
            SystemNowPlayingReader.fetch()
        }.value

        guard snap != lastSnapshot else { return }
        lastSnapshot = snap
        title = snap.title
        artist = snap.artist
        isPlaying = snap.isPlaying
        NotificationCenter.default.post(name: .islandNowPlayingDidChange, object: nil)
    }
}
