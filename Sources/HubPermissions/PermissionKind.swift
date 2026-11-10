import AppKit
import ApplicationServices
import Foundation

public enum PermissionKind: String, CaseIterable, Identifiable, Sendable {
    case accessibility
    case inputMonitoring
    case notifications
    case fullDiskAccess

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .accessibility: return "Accessibility"
        case .inputMonitoring: return "Input Monitoring"
        case .notifications: return "Notifications"
        case .fullDiskAccess: return "Full Disk Access"
        }
    }

    public var purpose: String {
        switch self {
        case .accessibility:
            return "Required for Device Control event filtering and emergency unlock detection."
        case .inputMonitoring:
            return "Required to monitor keyboard events for Device Control."
        case .notifications:
            return "Optional alerts for cleanup completion and monitor thresholds."
        case .fullDiskAccess:
            return "Not required for default cleaner scopes. Enable only if you extend scan paths."
        }
    }

    public var systemSettingsURL: URL? {
        switch self {
        case .accessibility:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        case .inputMonitoring:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
        case .notifications:
            return URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")
        case .fullDiskAccess:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
        }
    }
}

public enum PermissionStatus: String, Sendable {
    case granted
    case denied
    case unknown
    case notApplicable
}

public struct PermissionManager {
    public init() {}

    public func status(for kind: PermissionKind) -> PermissionStatus {
        switch kind {
        case .accessibility:
            return AXIsProcessTrusted() ? .granted : .denied
        case .inputMonitoring:
            if #available(macOS 10.15, *) {
                return CGPreflightListenEventAccess() ? .granted : .denied
            }
            return .unknown
        case .notifications:
            return .unknown
        case .fullDiskAccess:
            return .unknown
        }
    }

    public func requestIfNeeded(_ kind: PermissionKind) {
        switch kind {
        case .accessibility:
            let key = "AXTrustedCheckOptionPrompt" as CFString
            let opts = [key: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(opts)
        case .inputMonitoring:
            if #available(macOS 10.15, *) {
                _ = CGRequestListenEventAccess()
            }
        case .notifications, .fullDiskAccess:
            openSettings(for: kind)
        }
    }

    public func openSettings(for kind: PermissionKind) {
        guard let url = kind.systemSettingsURL else { return }
        NSWorkspace.shared.open(url)
    }
}
