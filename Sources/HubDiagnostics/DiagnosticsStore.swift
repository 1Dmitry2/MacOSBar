import Foundation
import Observation

public struct DiagnosticsEntry: Identifiable, Sendable, Codable {
    public let id: UUID
    public let date: Date
    public let level: String
    public let category: String
    public let message: String

    public init(id: UUID = UUID(), date: Date = Date(), level: String, category: String, message: String) {
        self.id = id
        self.date = date
        self.level = level
        self.category = category
        self.message = message
    }
}

@Observable
public final class DiagnosticsStore: @unchecked Sendable {
    public static let shared = DiagnosticsStore()

    public private(set) var entries: [DiagnosticsEntry] = []
    private let limit = 200

    private init() {}

    public func log(level: String, category: HubLogCategory, message: String) {
        let entry = DiagnosticsEntry(level: level, category: category.rawValue, message: message)
        Task { @MainActor in
            entries.insert(entry, at: 0)
            if entries.count > limit { entries.removeLast(entries.count - limit) }
        }
    }

    public func clear() {
        Task { @MainActor in entries.removeAll() }
    }

    public func exportReport(macSummary: String) -> String {
        let header = """
        MacOS Hub Diagnostic Report
        Generated: \(ISO8601DateFormatter().string(from: Date()))
        \(macSummary)

        """
        let body = entries.map { entry in
            "[\(entry.level)] \(entry.category) — \(entry.date.formatted()) — \(entry.message)"
        }.joined(separator: "\n")
        return header + body
    }
}
