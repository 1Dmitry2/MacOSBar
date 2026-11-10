import Foundation
import Observation

public struct CleanerHistoryRecord: Codable, Sendable {
    public var lastScanDate: Date?
    public var lastCleanDate: Date?
    public var totalFreedBytes: Int64
    public var lastFreedBytes: Int64
    public var lastScanFoundBytes: Int64
    public var failureMessages: [String]
}

@Observable
public final class CleanerHistoryStore: @unchecked Sendable {
    public static let shared = CleanerHistoryStore()

    private let defaults = UserDefaults.standard
    private let key = "cleaner.history"

    public private(set) var record: CleanerHistoryRecord

    private init() {
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(CleanerHistoryRecord.self, from: data) {
            record = decoded
        } else {
            record = CleanerHistoryRecord(
                lastScanDate: nil,
                lastCleanDate: nil,
                totalFreedBytes: 0,
                lastFreedBytes: 0,
                lastScanFoundBytes: 0,
                failureMessages: []
            )
        }
    }

    public func didFinishScan(foundBytes: Int64) {
        record.lastScanDate = Date()
        record.lastScanFoundBytes = foundBytes
        persist()
    }

    public func didFinishClean(freedBytes: Int64, failures: [String]) {
        record.lastCleanDate = Date()
        record.lastFreedBytes = freedBytes
        record.totalFreedBytes += freedBytes
        record.failureMessages = Array(failures.suffix(20))
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(record) {
            defaults.set(data, forKey: key)
        }
    }
}
