import Foundation
import HubSettings

@MainActor
final class MediaActivityProvider {
    private var pollTimer: Timer?
    var onChange: ((IslandActivity?) -> Void)?

    func start() {
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.publish() }
        }
        publish()
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        onChange?(nil)
    }

    private func publish() {
        guard AppConfiguration.shared.islandEventMediaEnabled else {
            onChange?(nil)
            return
        }
        NowPlayingMonitor.shared.refresh()
        let monitor = NowPlayingMonitor.shared
        guard monitor.title != nil || monitor.isPlaying else {
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
