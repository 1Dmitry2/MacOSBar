import AppKit
import HubSettings
import SwiftUI

/// Visual modes for settings live preview (and runtime compact/expanded where noted).
public enum IslandPresentationMode: String, CaseIterable, Identifiable, Sendable {
    case idle
    case hover
    case expanded
    case mic
    case camera
    case headphones
    case music
    case notification
    case multiple

    public var id: String { rawValue }

  /// Modes that use the expanded width bucket (preview layout).
    public var isExpandedLayout: Bool {
        switch self {
        case .idle:
            return false
        case .hover, .expanded, .mic, .camera, .headphones, .music, .notification, .multiple:
            return true
        }
    }

    /// Intermediate hover peek between compact and full expanded (preview only).
    public var isHoverPeek: Bool { self == .hover }
}

public enum IslandAnimationPolicy {
    public static var panelDuration: TimeInterval {
        let configured = DynamicIslandConfiguration.shared.runtimeSnapshot.animationDuration
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion { return 0.01 }
        return configured
    }

    public static var swiftUIAnimation: Animation? {
        if panelDuration <= 0.02 { return nil }
        return .spring(response: panelDuration, dampingFraction: 0.86)
    }

    public static var hoverExpandDelay: TimeInterval {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion { return 0.05 }
        return DynamicIslandConfiguration.shared.runtimeSnapshot.hoverDelaySeconds
    }

    public static var hoverCollapseDelay: TimeInterval {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion { return 0.05 }
        return DynamicIslandConfiguration.shared.runtimeSnapshot.hoverDelaySeconds * 0.65
    }
}
