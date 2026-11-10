import AppKit
import Foundation

/// Media controls via MediaRemote adapter (reliable for Music, Spotify, etc.), with HID fallback.
@MainActor
enum IslandMediaTransport {
    private enum RemoteCommand: Int {
        case togglePlayPause = 2
        case nextTrack = 4
        case previousTrack = 5
    }

    private enum SystemKey: Int {
        case playPause = 16
        case next = 17
        case previous = 18
    }

    static func togglePlayPause() {
        IslandInteractionSupport.activateForUserAction()
        if sendRemote(.togglePlayPause) {
            refreshAfterTransport()
            return
        }
        post(systemKey: .playPause)
        refreshAfterTransport()
    }

    static func skipForward() {
        IslandInteractionSupport.activateForUserAction()
        if sendRemote(.nextTrack) {
            refreshAfterTransport()
            return
        }
        post(systemKey: .next)
        refreshAfterTransport()
    }

    static func toggleShuffle() {
        IslandInteractionSupport.activateForUserAction()
    }

    static func skipBackward() {
        IslandInteractionSupport.activateForUserAction()
        if sendRemote(.previousTrack) {
            refreshAfterTransport()
            return
        }
        post(systemKey: .previous)
        refreshAfterTransport()
    }

    @discardableResult
    private static func sendRemote(_ command: RemoteCommand) -> Bool {
        guard let resources = IslandMediaRemoteAdapterResources.resolve() else { return false }
        let process = Process()
        let args = resources.sendCommandArguments(commandID: command.rawValue)
        process.executableURL = URL(fileURLWithPath: args[0])
        process.arguments = Array(args.dropFirst())
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private static func refreshAfterTransport() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            NowPlayingMonitor.shared.refresh()
        }
    }

    private static func post(systemKey: SystemKey) {
        let key = systemKey.rawValue
        let data1 = Int((key << 16) | (0xA << 8))
        guard
            let event = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: NSEvent.ModifierFlags(rawValue: 0xA00),
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8,
                data1: data1,
                data2: -1
            ),
            let cg = event.cgEvent
        else { return }
        cg.post(tap: .cgSessionEventTap)
        cg.post(tap: .cghidEventTap)
    }
}
