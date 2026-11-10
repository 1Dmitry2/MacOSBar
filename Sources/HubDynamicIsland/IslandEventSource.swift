import Foundation
import HubCore
import HubSettings

/// Settings-facing event sources aligned with `SystemEventManager.providerStatuses()`.
public enum IslandEventSourceID: String, CaseIterable, Identifiable, Sendable {
    case systemMetrics
    case microphone
    case camera
    case audioDevice
    case media
    case notification

    public var id: String { rawValue }

    public var localizationKey: String { "island.event.\(rawValue)" }
    public var statusNoteKey: String { "island.event.\(rawValue).note" }

    public var providerID: String? {
        switch self {
        case .systemMetrics: return nil
        case .microphone: return "microphone"
        case .camera: return CameraActivityProvider.isSupportedByPublicAPI ? "camera" : nil
        case .audioDevice: return "audioDevice"
        case .media: return "media"
        case .notification: return "notification"
        }
    }

    @MainActor
    public func providerStatus() -> SystemEventProviderStatus? {
        guard let providerID else {
            return SystemEventProviderStatus(
                id: "systemMetrics",
                isSupported: true,
                limitation: L10n.tr("island.event.systemMetrics.note")
            )
        }
        return SystemEventManager.shared.providerStatuses().first { $0.id == providerID }
    }

    @MainActor
    public var isImplemented: Bool {
        providerStatus()?.isSupported ?? true
    }

    @MainActor
    public func limitationText() -> String? {
        if let note = providerStatus()?.limitation { return note }
        return L10n.tr(statusNoteKey)
    }

    @MainActor
    public func isEnabled(in config: DynamicIslandConfiguration) -> Bool {
        guard isImplemented else { return false }
        switch self {
        case .systemMetrics: return config.islandEventSystemMetricsEnabled
        case .microphone: return config.islandEventMicrophoneEnabled
        case .camera: return config.islandEventCameraEnabled
        case .audioDevice: return config.islandEventAudioDeviceEnabled
        case .media: return config.islandEventMediaEnabled
        case .notification: return config.islandEventNotificationsEnabled
        }
    }

    @MainActor
    public func setEnabled(_ value: Bool, in config: DynamicIslandConfiguration) {
        guard isImplemented else { return }
        switch self {
        case .systemMetrics: config.islandEventSystemMetricsEnabled = value
        case .microphone: config.islandEventMicrophoneEnabled = value
        case .camera: config.islandEventCameraEnabled = value
        case .audioDevice: config.islandEventAudioDeviceEnabled = value
        case .media: config.islandEventMediaEnabled = value
        case .notification: config.islandEventNotificationsEnabled = value
        }
        if !value { clearCachedActivity() }
    }

    @MainActor
    private func clearCachedActivity() {
        let state = DynamicIslandStateManager.shared
        switch self {
        case .microphone:
            state.upsertPersistent(nil, clearID: "microphone.active")
        case .camera:
            state.upsertPersistent(nil, clearID: "camera.active")
        case .media:
            state.upsertPersistent(nil, clearID: "media.nowplaying")
        case .audioDevice:
            state.removeActivities(kind: .audioDevice)
        case .notification:
            state.dismissTransient()
        case .systemMetrics:
            break
        }
    }
}
