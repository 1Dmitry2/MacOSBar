import Foundation
import HubSettings
import UserNotifications

/// Delivers island activities for notifications posted to **this app** only.
@MainActor
final class NotificationActivityProvider: NSObject {
    var onTransient: ((IslandActivity) -> Void)?

    static let systemWideUnsupportedReason =
        "macOS does not expose Notification Center traffic from other apps to third-party processes."

    private var canUseNotificationCenter: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    func start() {
        guard canUseNotificationCenter else { return }
        UNUserNotificationCenter.current().delegate = self
    }

    func stop() {
        guard canUseNotificationCenter else { return }
        UNUserNotificationCenter.current().delegate = nil
    }
}

extension NotificationActivityProvider: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let title = notification.request.content.title
        let body = notification.request.content.body
        await MainActor.run {
            self.emitIfEnabled(title: title, body: body)
        }
        return []
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let title = response.notification.request.content.title
        let body = response.notification.request.content.body
        await MainActor.run {
            self.emitIfEnabled(title: title, body: body)
        }
    }

    @MainActor
    private func emitIfEnabled(title: String, body: String) {
        guard AppConfiguration.shared.islandEventNotificationsEnabled else { return }
        let activity = IslandActivity(
            id: UUID().uuidString,
            kind: .notification,
            title: title,
            subtitle: body.isEmpty ? nil : body,
            systemImage: "bell.badge.fill",
            isPersistent: false
        )
        onTransient?(activity)
    }
}
