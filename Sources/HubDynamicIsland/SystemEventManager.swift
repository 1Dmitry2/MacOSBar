import Foundation
import HubDiagnostics

public struct SystemEventProviderStatus: Sendable, Equatable {
    public let id: String
    public let isSupported: Bool
    public let limitation: String?

    public init(id: String, isSupported: Bool, limitation: String?) {
        self.id = id
        self.isSupported = isSupported
        self.limitation = limitation
    }
}

@MainActor
public final class SystemEventManager {
    public static let shared = SystemEventManager()

    private let log = HubLogger.log(.island)
    private let microphone = MicrophoneActivityProvider()
    private let camera = CameraActivityProvider()
    private let audioDevice = AudioDeviceActivityProvider()
    private let media = MediaActivityProvider()
    private let notifications = NotificationActivityProvider()

    private var running = false

    private init() {}

    private static var isRunningUnderTests: Bool {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return true }
        let path = Bundle.main.bundlePath
        return path.contains("xctest") || path.hasSuffix(".xctest")
    }

    public var cameraDetectionSupported: Bool {
        CameraActivityProvider.isSupportedByPublicAPI
    }

    public func providerStatuses() -> [SystemEventProviderStatus] {
        [
            SystemEventProviderStatus(
                id: "microphone",
                isSupported: true,
                limitation: "Core Audio running flag on default input; heuristic, not per-app."
            ),
            SystemEventProviderStatus(
                id: "camera",
                isSupported: cameraDetectionSupported,
                limitation: CameraActivityProvider.publicAPILimitation
            ),
            SystemEventProviderStatus(
                id: "audioDevice",
                isSupported: true,
                limitation: "Default output device name/transport via Core Audio."
            ),
            SystemEventProviderStatus(
                id: "media",
                isSupported: true,
                limitation: "System Now Playing via MediaRemote when available; else MPNowPlayingInfoCenter."
            ),
            SystemEventProviderStatus(
                id: "notification",
                isSupported: true,
                limitation: NotificationActivityProvider.systemWideUnsupportedReason
            ),
        ]
    }

    public func start() {
        guard !running else { return }
        running = true
        wireProviders()
        microphone.start()
        camera.start()
        audioDevice.start()
        media.start()
        if !Self.isRunningUnderTests {
            notifications.start()
        }
        log.debug("SystemEventManager started")
    }

    public func stop() {
        guard running else { return }
        running = false
        microphone.stop()
        camera.stop()
        audioDevice.stop()
        media.stop()
        notifications.stop()
        DynamicIslandStateManager.shared.clearSystemActivities()
        IslandStateManager.shared.showLiveActivity(false)
        log.debug("SystemEventManager stopped")
    }

    private func wireProviders() {
        let activityState = DynamicIslandStateManager.shared
        let presentation = IslandStateManager.shared

        microphone.onChange = { activity in
            if let activity {
                activityState.upsertPersistent(activity, clearID: nil)
            } else {
                activityState.upsertPersistent(nil, clearID: "microphone.active")
            }
        }

        camera.onChange = { activity in
            if let activity {
                activityState.upsertPersistent(activity, clearID: nil)
            } else {
                activityState.upsertPersistent(nil, clearID: "camera.active")
            }
        }

        audioDevice.onChange = { activity in
            if let activity {
                activityState.upsertPersistent(activity, clearID: nil)
            } else {
                activityState.removeActivities(kind: .audioDevice)
            }
        }

        media.onChange = { activity in
            if let activity {
                activityState.upsertPersistent(activity, clearID: nil)
            } else {
                activityState.upsertPersistent(nil, clearID: "media.nowplaying")
            }
        }

        notifications.onTransient = { activity in
            activityState.showTransient(activity)
            presentation.enqueueNotification(.notification)
        }
    }
}
