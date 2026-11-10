import Foundation
import HubDiagnostics
import HubSettings
import SwiftUI

@MainActor
public final class IslandStateManager: ObservableObject {
    public static let shared = IslandStateManager()

    @Published public private(set) var phase: IslandInteractionPhase = .idle
    @Published public private(set) var presentationOverride: IslandPresentationMode?

    private var notificationQueue: [IslandPresentationMode] = []
    private var activeNotification: IslandPresentationMode?
    private var hoverTask: Task<Void, Never>?
    private var notificationTask: Task<Void, Never>?
    private let log = HubLogger.log(.island)

    private init() {}

    public var presentationMode: IslandPresentationMode {
        if let presentationOverride { return presentationOverride }
        switch phase {
        case .idle:
            return .idle
        case .hover:
            return .hover
        case .expanded, .interactive:
            return .expanded
        case .liveActivity:
            return .music
        case .multiple:
            return .multiple
        case .notification:
            return activeNotification ?? .notification
        }
    }

    /// User-pinned expanded (click / shortcut), not hover peek.
    public var isExpanded: Bool { phase.isUserExpanded }

    public func setExpanded(_ value: Bool, source: IslandTransitionSource = .programmatic) {
        _ = source
        hoverTask?.cancel()
        hoverTask = nil
        if value {
            transition(to: .expanded)
        } else {
            switch phase {
            case .expanded, .interactive, .hover:
                transition(to: .idle)
            default:
                break
            }
        }
    }

    public func toggleExpanded() {
        hoverTask?.cancel()
        hoverTask = nil
        presentationOverride = nil
        if isExpanded {
            transition(to: .idle)
        } else {
            transition(to: .expanded)
        }
    }

    public func hoverChanged(inside: Bool, hoverExpands: Bool) {
        hoverTask?.cancel()
        guard hoverExpands else {
            if !inside, phase == .hover {
                transition(to: .idle)
            }
            return
        }

        if inside {
            guard phase == .idle else { return }
            let delay = IslandAnimationPolicy.hoverExpandDelay
            hoverTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let self, self.phase == .idle else { return }
                    self.transition(to: .hover)
                }
            }
        } else {
            guard phase == .hover else { return }
            let delay = IslandAnimationPolicy.hoverCollapseDelay
            hoverTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let self, self.phase == .hover else { return }
                    self.transition(to: .idle)
                }
            }
        }
    }

    public func enqueueNotification(
        _ mode: IslandPresentationMode = .notification,
        duration: TimeInterval? = nil
    ) {
        let defaultDuration = duration ?? AppConfiguration.shared.islandNotificationDurationSeconds
        notificationQueue.append(mode)
        drainNotificationQueueIfNeeded(defaultDuration: defaultDuration)
    }

    public func showLiveActivity(_ active: Bool) {
        if active {
            transition(to: .liveActivity)
        } else if phase == .liveActivity {
            transition(to: .idle)
        }
    }

    public func syncMultipleActivityPhase(activityCount: Int) {
        // Activity stacks render as compact icons; only clear stale `.multiple` phase.
        if activityCount <= 1, phase == .multiple {
            transition(to: .idle)
        }
    }

    public func reset() {
        hoverTask?.cancel()
        notificationTask?.cancel()
        notificationQueue.removeAll()
        activeNotification = nil
        presentationOverride = nil
        phase = .idle
    }

    private func transition(to newPhase: IslandInteractionPhase) {
        guard phase != newPhase else { return }
        log.info("Island phase \(self.phase.rawValue) → \(newPhase.rawValue)")
        phase = newPhase
    }

    private func drainNotificationQueueIfNeeded(defaultDuration: TimeInterval) {
        guard notificationTask == nil, activeNotification == nil, let next = notificationQueue.first else { return }
        notificationQueue.removeFirst()
        activeNotification = next
        presentationOverride = next
        transition(to: .notification)
        notificationTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(defaultDuration))
            await MainActor.run {
                guard let self else { return }
                self.activeNotification = nil
                self.presentationOverride = nil
                self.notificationTask = nil
                self.transition(to: .idle)
                self.drainNotificationQueueIfNeeded(defaultDuration: defaultDuration)
            }
        }
    }
}

public enum IslandTransitionSource: Sendable {
    case tap
    case hover
    case programmatic
}
