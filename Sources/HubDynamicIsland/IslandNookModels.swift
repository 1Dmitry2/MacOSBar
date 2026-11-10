import Foundation

public enum IslandNookSection: String, CaseIterable, Identifiable, Sendable, Codable {
    case music
    case monitor
    case focus
    case calendar
    case tasks

    /// Sections shown in the dock (tasks removed from product UI).
    public static let dockCases: [IslandNookSection] = [.music, .monitor, .focus, .calendar]

    public var id: String { rawValue }

    public var systemImage: String {
        switch self {
        case .music: return "play.fill"
        case .monitor: return "waveform.path.ecg"
        case .focus: return "timer"
        case .calendar: return "calendar"
        case .tasks: return "checklist"
        }
    }

    public var localizationKey: String {
        "island.nook.section.\(rawValue)"
    }
}

public enum IslandFocusMode: String, Codable, Sendable {
    case concentration
    case breakTime
}
