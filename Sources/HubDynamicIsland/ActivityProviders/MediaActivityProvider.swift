import Foundation
import HubSettings

@MainActor
final class MediaActivityProvider {
    private var pollTimer: Timer?
    var onChange: ((IslandActivity?) -> Void)?

    private var remoteObserver: NSObjectProtocol?

    func start() {
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.publish() }
        }
        remoteObserver = NotificationCenter.default.addObserver(
            forName: .islandNowPlayingDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.publish() }
        }
        publish()
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        if let remoteObserver { NotificationCenter.default.removeObserver(remoteObserver) }
        remoteObserver = nil
        onChange?(nil)
    }

    private func publish() {
        guard AppConfiguration.shared.islandEventMediaEnabled else {
            onChange?(nil)
            return
        }
        NowPlayingMonitor.shared.refresh()
        let monitor = NowPlayingMonitor.shared
        guard monitor.isPlaying else {
            onChange?(nil)
            return
        }
        onChange?(
            IslandActivity(
                id: "media.nowplaying",
                kind: .media,
                title: monitor.title ?? "Now Playing",
                subtitle: monitor.artist,
                systemImage: monitor.isPlaying ? "play.fill" : "pause.fill"
            )
        )
    }
}
