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

    public var isExpandedInteraction: Bool {
        switch self {
        case .idle: return false
        case .hover, .expanded, .liveActivity, .multiple, .notification, .interactive: return true
        }
    }
}
