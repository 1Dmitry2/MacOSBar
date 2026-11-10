import Foundation
import HubSettings

public enum IslandActivityKind: String, Sendable, CaseIterable {
    case microphone, camera, audioDevice, media, notification
}

public struct IslandActivity: Identifiable, Sendable, Equatable {
    public let id: String
    public let kind: IslandActivityKind
    public var title: String
    public var subtitle: String?
    public var systemImage: String
    public var isPersistent: Bool

    public init(
        id: String,
        kind: IslandActivityKind,
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        isPersistent: Bool = true
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.isPersistent = isPersistent
    }
}

@MainActor
@Observable
public final class DynamicIslandStateManager {
    public static let shared = DynamicIslandStateManager()

    public private(set) var persistentActivities: [IslandActivity] = []
    public private(set) var transientBanner: IslandActivity?

    private init() {}

    public var sortedActivities: [IslandActivity] {
        persistentActivities
    }

    public var compactActivityIcons: [IslandActivity] {
        let limit = max(1, AppConfiguration.shared.islandMaxCompactActivityIcons)
        return Array(persistentActivities.prefix(limit))
    }

    public func upsertPersistent(_ activity: IslandActivity?, clearID: String?) {
        if let clearID {
            persistentActivities.removeAll { $0.id == clearID }
        }
        guard let activity else {
            publishSnapshot()
            return
        }
        if let index = persistentActivities.firstIndex(where: { $0.id == activity.id }) {
            persistentActivities[index] = activity
        } else {
            persistentActivities.append(activity)
        }
        publishSnapshot()
        IslandStateManager.shared.syncMultipleActivityPhase(
            activityCount: persistentActivities.count
        )
    }

    public func removeActivities(kind: IslandActivityKind) {
        persistentActivities.removeAll { $0.kind == kind }
        publishSnapshot()
        IslandStateManager.shared.syncMultipleActivityPhase(
            activityCount: persistentActivities.count
        )
    }

    public func clearSystemActivities() {
        persistentActivities = []
        transientBanner = nil
        publishSnapshot()
        IslandStateManager.shared.syncMultipleActivityPhase(activityCount: 0)
    }

    public func showTransient(_ activity: IslandActivity) {
        transientBanner = activity
        publishSnapshot()
        IslandStateManager.shared.syncMultipleActivityPhase(
            activityCount: persistentActivities.count
        )
    }

    public func dismissTransient() {
        transientBanner = nil
        publishSnapshot()
    }

  private func publishSnapshot() {
        let mic = persistentActivities.contains { $0.kind == .microphone }
        let cam = persistentActivities.contains { $0.kind == .camera }
        IslandSystemEventViewModel.shared.apply(
            SystemEventSnapshot(
                microphoneActive: mic,
                cameraActive: cam,
                activities: persistentActivities,
                transient: transientBanner
            )
        )
    }
}

public struct SystemEventSnapshot: Sendable, Equatable {
    public static let empty = SystemEventSnapshot(
        microphoneActive: false,
        cameraActive: false,
        activities: [],
        transient: nil
    )

    public var microphoneActive: Bool
    public var cameraActive: Bool
    public var activities: [IslandActivity]
    public var transient: IslandActivity?

    public var suggestedPresentation: IslandPresentationMode? {
        if let transient {
            switch transient.kind {
            case .audioDevice: return .headphones
            case .microphone: return .mic
            case .camera: return .camera
            case .media: return .music
            case .notification: return .notification
            }
        }
        if activities.count > 1, AppConfiguration.shared.islandMultiActivityEnabled {
            return .multiple
        }
        if activities.count > 1 {
            return singleActivityPresentation(from: activities)
        }
        if activities.contains(where: { $0.kind == .media }) { return .music }
        if activities.contains(where: { $0.kind == .microphone }) { return .mic }
        if activities.contains(where: { $0.kind == .camera }) { return .camera }
        return nil
    }

    private func singleActivityPresentation(from activities: [IslandActivity]) -> IslandPresentationMode? {
        guard let first = activities.first else { return nil }
        switch first.kind {
        case .microphone: return .mic
        case .camera: return .camera
        case .audioDevice: return .headphones
        case .media: return .music
        case .notification: return .notification
        }
    }
}

@MainActor
@Observable
public final class IslandSystemEventViewModel {
    public static let shared = IslandSystemEventViewModel()

    public private(set) var snapshot: SystemEventSnapshot = .empty

    private init() {}

    func apply(_ snapshot: SystemEventSnapshot) {
        self.snapshot = snapshot
    }
}
