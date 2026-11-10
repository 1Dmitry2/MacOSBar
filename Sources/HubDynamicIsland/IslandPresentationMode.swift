import AppKit
import HubSettings
import SwiftUI

/// Visual modes for the island UI (settings preview + runtime compact/expanded).
public enum IslandPresentationMode: String, CaseIterable, Identifiable, Sendable {
    case compact
    case expanded
    case notification
    case activity
    case music
    case systemMonitor

    public var id: String { rawValue }

    public var isExpandedLayout: Bool {
        switch self {
        case .compact: return false
        case .expanded, .notification, .activity, .music, .systemMonitor: return true
        }
    }
}

public enum IslandAnimationPolicy {
    public static var panelDuration: TimeInterval {
        let configured = AppConfiguration.shared.islandAnimationDuration
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion { return 0.01 }
        return configured
    }

    public static var swiftUIAnimation: Animation? {
        if panelDuration <= 0.02 { return nil }
        return .spring(response: panelDuration, dampingFraction: 0.86)
    }
}
