import Foundation
import HubSettings

@MainActor
final class MediaActivityProvider {
    private var pollTimer: Timer?
    var onChange: ((IslandActivity?) -> Void)?

    private var remoteObserver: NSObjectProtocol?
    private var lastTrackSignature: String?

    func start() {
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
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
        lastTrackSignature = nil
        onChange?(nil)
        IslandStateManager.shared.showLiveActivity(false)
    }

    private func publish() {
        guard AppConfiguration.shared.islandEventMediaEnabled else {
            onChange?(nil)
            IslandStateManager.shared.showLiveActivity(false)
            return
        }
        NowPlayingMonitor.shared.refresh()
        let monitor = NowPlayingMonitor.shared
        let active = monitor.isPlaying || (monitor.title?.isEmpty == false)
        guard active else {
            onChange?(nil)
            lastTrackSignature = nil
            IslandStateManager.shared.showLiveActivity(false)
            return
        }

        let signature = [monitor.title, monitor.artist].compactMap { $0 }.joined(separator: " · ")
        if signature != lastTrackSignature, !signature.isEmpty {
            lastTrackSignature = signature
            let snap = DynamicIslandConfiguration.shared.runtimeSnapshot
            if snap.mediaExpandOnTrackChange,
               !IslandStateManager.shared.isExpanded,
               IslandStateManager.shared.phase == .idle {
                let duration = snap.notificationDurationSeconds
                IslandStateManager.shared.enqueueNotification(.music, duration: min(duration, 4))
            }
        }

        DynamicIslandStateManager.shared.removeActivities(kind: .audioDevice)

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
