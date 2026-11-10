import AppKit
import Foundation
import MediaPlayer
import Observation

@MainActor
@Observable
public final class NowPlayingMonitor: @unchecked Sendable {
    public static let shared = NowPlayingMonitor()

    public private(set) var title: String?
    public private(set) var artist: String?
    public private(set) var album: String?
    public private(set) var isPlaying = false
    public private(set) var artwork: NSImage?

    private var timer: Timer?
    private var remoteObserverInstalled = false
    private var refreshInFlight = false
    private var lastSnapshot = SystemNowPlayingReader.Snapshot.empty
    private let mediaStream = IslandMediaRemoteStream()
    private var adapterPreferred = false

    private init() {
        mediaStream.onUpdate = { [weak self] update in
            Task { @MainActor in
                self?.applyStreamUpdate(update)
            }
        }
        mediaStream.start()
        installRemoteObserverIfNeeded()
        enqueueRefresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.enqueueRefresh()
        }
    }

    private func applyStreamUpdate(_ update: IslandMediaRemoteStream.Update?) {
        guard let update else { return }
        adapterPreferred = true
        let snap = SystemNowPlayingReader.Snapshot(
            title: update.title,
            artist: update.artist,
            isPlaying: update.isPlaying
        )
        let artworkImage = update.artworkData.flatMap { NSImage(data: $0) }
        let metadataChanged = snap != lastSnapshot
        let artworkChanged = artwork != artworkImage
        guard metadataChanged || artworkChanged else { return }
        lastSnapshot = snap
        title = snap.title
        artist = snap.artist
        album = update.album
        isPlaying = snap.isPlaying
        artwork = artworkImage
        NotificationCenter.default.post(name: .islandNowPlayingDidChange, object: nil)
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
        if adapterPreferred, title != nil { return }
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
