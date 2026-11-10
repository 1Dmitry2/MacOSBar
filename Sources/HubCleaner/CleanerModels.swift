import Foundation

public enum CleanerCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case userTempFiles
    case userCaches
    case appTempFiles
    case diagnosticLogs
    case installerLeftovers
    case devCaches

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .userTempFiles: return "User Temp Files"
        case .userCaches: return "Safe User Caches"
        case .appTempFiles: return "Application Temp"
        case .diagnosticLogs: return "Diagnostic Logs"
        case .installerLeftovers: return "Installer Leftovers"
        case .devCaches: return "Development Caches"
        }
    }

    public var summary: String {
        switch self {
        case .userTempFiles: return "Temporary files in user tmp folders."
        case .userCaches: return "Regenerable cache from ~/Library/Caches (excluding browser profiles)."
        case .appTempFiles: return "Temporary items from /var/folders user temp."
        case .diagnosticLogs: return "Stale logs in ~/Library/Logs older than 14 days."
        case .installerLeftovers: return "Leftover .pkg download artifacts in safe temp only."
        case .devCaches: return "Xcode DerivedData and SwiftPM caches (optional)."
        }
    }

    public var defaultSelected: Bool {
        switch self {
        case .userTempFiles, .userCaches, .appTempFiles, .diagnosticLogs: return true
        case .installerLeftovers, .devCaches: return false
        }
    }
}

public struct CleanerItem: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let url: URL
    public let category: CleanerCategory
    public let sizeBytes: Int64
    public let reason: String

    public init(id: UUID = UUID(), url: URL, category: CleanerCategory, sizeBytes: Int64, reason: String) {
        self.id = id
        self.url = url
        self.category = category
        self.sizeBytes = sizeBytes
        self.reason = reason
    }
}

public struct CleanerCategoryResult: Sendable, Equatable {
    public var category: CleanerCategory
    public var items: [CleanerItem]
    public var totalBytes: Int64 { items.reduce(0) { $0 + $1.sizeBytes } }
    public var isSelected: Bool
}

public enum CleanerPhase: Sendable, Equatable {
    case idle
    case scanning(progress: Double)
    case preview(results: [CleanerCategoryResult])
    case cleaning(progress: Double)
    case completed(freedBytes: Int64)
    case failed(message: String)
}
