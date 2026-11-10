import Foundation

/// Runtime interaction phases for the floating island (distinct from settings preview `IslandPresentationMode`).
public enum IslandInteractionPhase: String, Sendable, Equatable {
    case idle
    case hover
    case expanded
    case liveActivity
    case multiple
    case notification
    case interactive

    /// Click- or shortcut-pinned expanded layout (not hover peek).
    public var isUserExpanded: Bool {
        switch self {
        case .expanded, .interactive: return true
        default: return false
        }
    }

    /// Phases that use expanded width/height buckets (hover peek, activities, notifications).
    public var isExpandedInteraction: Bool {
        switch self {
        case .idle: return false
        case .hover, .expanded, .liveActivity, .multiple, .notification, .interactive: return true
        }
    }
}
