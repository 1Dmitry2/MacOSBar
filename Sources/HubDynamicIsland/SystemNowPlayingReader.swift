import Foundation
import MediaPlayer

/// Reads system Now Playing (Chrome, Music, etc.) via MediaRemote with MPNowPlaying fallback.
enum SystemNowPlayingReader {
    struct Snapshot: Sendable, Equatable {
        var title: String?
        var artist: String?
        var isPlaying: Bool
        static let empty = Snapshot(title: nil, artist: nil, isPlaying: false)
    }

    static func registerForUpdates(_ handler: @escaping @Sendable () -> Void) {
        let name = CFNotificationName(
            "com.apple.Mediaremote.nowplayinginfo.didchange" as CFString
        )
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(ObserverToken(handler: handler)).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer else { return }
                let token = Unmanaged<ObserverToken>.fromOpaque(observer).takeUnretainedValue()
                token.handler()
            },
            name.rawValue,
            nil,
            .deliverImmediately
        )
    }

    static func current() -> Snapshot {
        if let remote = mediaRemoteSnapshot() { return remote }
        return mpNowPlayingSnapshot()
    }

    private static func mpNowPlayingSnapshot() -> Snapshot {
        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        let title = info?[MPMediaItemPropertyTitle] as? String
        let artist = info?[MPMediaItemPropertyArtist] as? String
        let rate = info?[MPNowPlayingInfoPropertyPlaybackRate] as? Double
        let playing = rate.map { $0 > 0.01 } ?? (title != nil && (rate ?? 1) > 0)
        guard playing, title != nil else { return .empty }
        return Snapshot(title: title, artist: artist, isPlaying: true)
    }

    private static func mediaRemoteSnapshot() -> Snapshot? {
        guard let handle = dlopen(
            "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
            RTLD_LAZY
        ) else { return nil }
        defer { dlclose(handle) }

        let playing = applicationIsPlaying(handle: UnsafeMutableRawPointer(handle))
        guard playing else { return nil }

        typealias GetInfo = @convention(c) (DispatchQueue, @escaping (CFDictionary?) -> Void) -> Void
        guard let getInfoPtr = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") else { return nil }
        let getInfo = unsafeBitCast(getInfoPtr, to: GetInfo.self)

        var captured: CFDictionary?
        let latch = DispatchSemaphore(value: 0)
        getInfo(DispatchQueue.main) { info in
            captured = info
            latch.signal()
        }
        _ = latch.wait(timeout: .now() + 0.6)
        guard let raw = captured as? [AnyHashable: Any] else {
            return Snapshot(title: "Now Playing", artist: nil, isPlaying: true)
        }

        let flat = flattenMetadata(raw)
        let title =
            firstString(flat, keys: titleKeys)
            ?? firstString(raw, keys: titleKeys)
        let artist =
            firstString(flat, keys: artistKeys)
            ?? firstString(raw, keys: artistKeys)
        let appName = firstString(raw, keys: ["kMRMediaRemoteNowPlayingInfoApplicationDisplayName"])
        let resolvedTitle = [title, appName, playing ? "Now Playing" : nil]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }

        return Snapshot(title: resolvedTitle, artist: artist, isPlaying: playing)
    }

    private static func applicationIsPlaying(handle: UnsafeMutableRawPointer) -> Bool {
        typealias IsPlaying = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
        guard let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying") else { return true }
        let fn = unsafeBitCast(sym, to: IsPlaying.self)
        var playing = false
        let latch = DispatchSemaphore(value: 0)
        fn(DispatchQueue.main) { value in
            playing = value
            latch.signal()
        }
        _ = latch.wait(timeout: .now() + 0.5)
        return playing
    }

    private static let titleKeys = [
        "kMRMediaRemoteNowPlayingInfoTitle",
        "kMRMediaRemoteNowPlayingInfoDisplayTitle",
        "kMRMediaRemoteNowPlayingInfoDescription",
        "title",
        "Title",
    ]

    private static let artistKeys = [
        "kMRMediaRemoteNowPlayingInfoArtist",
        "kMRMediaRemoteNowPlayingInfoAlbumArtist",
        "artist",
        "Artist",
    ]

    private static func flattenMetadata(_ root: [AnyHashable: Any]) -> [String: Any] {
        var out: [String: Any] = [:]
        func walk(_ dict: [AnyHashable: Any]) {
            for (k, v) in dict {
                if let key = k as? String {
                    if let nested = v as? [AnyHashable: Any] {
                        walk(nested)
                    } else if let s = v as? String {
                        out[key] = s
                    } else if let n = v as? NSNumber {
                        out[key] = n
                    }
                }
            }
        }
        walk(root)
        return out
    }

    private static func firstString(_ dict: [AnyHashable: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = dict[key] as? String, !value.isEmpty { return value }
            for (rawKey, value) in dict where (rawKey as? String) == key {
                if let s = value as? String, !s.isEmpty { return s }
            }
        }
        return nil
    }

    private final class ObserverToken: @unchecked Sendable {
        let handler: @Sendable () -> Void
        init(handler: @escaping @Sendable () -> Void) { self.handler = handler }
    }
}
