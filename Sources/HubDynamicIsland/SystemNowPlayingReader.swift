import Foundation
import MediaPlayer

/// Reads the system Now Playing source (Control Center / Chrome / Music.app). Falls back to `MPNowPlayingInfoCenter`.
enum SystemNowPlayingReader {
    struct Snapshot: Sendable, Equatable {
        var title: String?
        var artist: String?
        var isPlaying: Bool
    }

    static func current() -> Snapshot {
        if let remote = mediaRemoteSnapshot() {
            return remote
        }
        return mpNowPlayingSnapshot()
    }

    private static func mpNowPlayingSnapshot() -> Snapshot {
        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        let title = info?[MPMediaItemPropertyTitle] as? String
        let artist = info?[MPMediaItemPropertyArtist] as? String
        let rate = info?[MPNowPlayingInfoPropertyPlaybackRate] as? Double
        let playing = rate.map { $0 > 0.01 } ?? (title != nil)
        return Snapshot(title: title, artist: artist, isPlaying: playing)
    }

    // MARK: - MediaRemote (system-wide; required for Chrome and most browser tabs)

    private static func mediaRemoteSnapshot() -> Snapshot? {
        guard let handle = dlopen(
            "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
            RTLD_LAZY
        ) else { return nil }
        defer { dlclose(handle) }

        typealias GetInfo = @convention(c) (DispatchQueue, @escaping (CFDictionary?) -> Void) -> Void
        guard let getInfoPtr = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") else { return nil }
        let getInfo = unsafeBitCast(getInfoPtr, to: GetInfo.self)

        var captured: CFDictionary?
        let latch = DispatchSemaphore(value: 0)
        getInfo(DispatchQueue.global(qos: .utility)) { info in
            captured = info
            latch.signal()
        }
        _ = latch.wait(timeout: .now() + 0.35)
        guard let raw = captured as? [AnyHashable: Any] else { return nil }

        let title = metadataString(raw, keys: [
            "kMRMediaRemoteNowPlayingInfoTitle",
            "kMRMediaRemoteNowPlayingInfoDisplayTitle",
            "title",
        ])
        let artist = metadataString(raw, keys: [
            "kMRMediaRemoteNowPlayingInfoArtist",
            "artist",
        ])
        let rate = numberValue(raw, keys: [
            "kMRMediaRemoteNowPlayingInfoPlaybackRate",
            "playbackRate",
        ])?.doubleValue
        let playing = rate.map { $0 > 0.01 } ?? (title != nil)
        let appName = metadataString(raw, keys: [
            "kMRMediaRemoteNowPlayingInfoApplicationDisplayName",
        ])
        let resolvedTitle = title ?? (playing ? appName : nil)
        guard resolvedTitle != nil else { return nil }
        return Snapshot(title: resolvedTitle, artist: artist, isPlaying: playing)
    }

    private static func metadataString(_ dict: [AnyHashable: Any], keys: [String]) -> String? {
        for key in keys {
            for (rawKey, value) in dict {
                guard let k = rawKey as? String, k == key else { continue }
                if let s = value as? String, !s.isEmpty { return s }
                if let s = value as? NSString as String?, !s.isEmpty { return s }
            }
        }
        return nil
    }

    private static func numberValue(_ dict: [AnyHashable: Any], keys: [String]) -> NSNumber? {
        for key in keys {
            for (rawKey, value) in dict {
                guard let k = rawKey as? String, k == key else { continue }
                if let n = value as? NSNumber { return n }
            }
        }
        return nil
    }
}
