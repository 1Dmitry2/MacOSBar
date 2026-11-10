import EventKit
import Foundation
import HubCore
import HubDiagnostics
import Observation

public struct IslandCalendarEvent: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let start: Date
    public let end: Date
    public let isAllDay: Bool
}

@MainActor
@Observable
public final class IslandCalendarReader {
    public static let shared = IslandCalendarReader()

    public private(set) var authorization: EKAuthorizationStatus = .notDetermined
    public private(set) var events: [IslandCalendarEvent] = []
    public private(set) var lastRefresh = Date.distantPast

    private let store = EKEventStore()
    private let log = HubLogger.log(.island)

    private init() {
        authorization = EKEventStore.authorizationStatus(for: .event)
        if authorization == .fullAccess || authorization == .authorized {
            reloadEvents()
        }
    }

    public func requestAccessAndReload() {
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { [weak self] granted, error in
                Task { @MainActor in
                    self?.authorization = EKEventStore.authorizationStatus(for: .event)
                    if let error {
                        self?.log.error("Calendar access error: \(error.localizedDescription)")
                    }
                    if granted {
                        self?.reloadEvents()
                    }
                }
            }
        }
    }

    public func reloadEvents() {
        authorization = EKEventStore.authorizationStatus(for: .event)
        guard authorization == .fullAccess || authorization == .authorized else { return }
        let start = Calendar.current.startOfDay(for: Date())
        guard let end = Calendar.current.date(byAdding: .day, value: 7, to: start) else { return }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let raw = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
        events = raw.prefix(12).map { event in
            IslandCalendarEvent(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? L10n.tr("island.nook.calendar.untitled"),
                start: event.startDate,
                end: event.endDate,
                isAllDay: event.isAllDay
            )
        }
        lastRefresh = Date()
    }
}
