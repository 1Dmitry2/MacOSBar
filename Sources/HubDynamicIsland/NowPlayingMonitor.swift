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

    private init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    public func refresh() {
        let snap = SystemNowPlayingReader.current()
        title = snap.title
        artist = snap.artist
        isPlaying = snap.isPlaying
    }
}
