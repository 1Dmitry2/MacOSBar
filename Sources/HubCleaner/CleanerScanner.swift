import Foundation
import HubDiagnostics
import Observation

@Observable
public final class CleanerEngine: @unchecked Sendable {
    public private(set) var phase: CleanerPhase = .idle
    public private(set) var categoryResults: [CleanerCategoryResult] = []

    private let validator = SafetyValidator()
    private let allowlist: [URL]
    private let log = HubLogger.log(.cleaner)

    public init(allowlist: [URL] = SafetyValidator.defaultAllowlist()) {
        self.allowlist = allowlist
    }

    public func scan(categories: Set<CleanerCategory>) async {
        await MainActor.run { phase = .scanning(progress: 0) }
        var results: [CleanerCategoryResult] = []
        let all = CleanerCategory.allCases.filter { categories.contains($0) }
        for (index, cat) in all.enumerated() {
            let items = await scanCategory(cat)
            let filtered = items.filter { item in
                validator.isDeletionCandidateSafe(item.url, allowlistRoots: allowlist).0
            }
            results.append(CleanerCategoryResult(category: cat, items: filtered, isSelected: cat.defaultSelected))
            let progress = Double(index + 1) / Double(all.count)
            await MainActor.run { phase = .scanning(progress: progress) }
        }
        let found = results.reduce(Int64(0)) { $0 + $1.totalBytes }
        CleanerHistoryStore.shared.didFinishScan(foundBytes: found)
        await MainActor.run {
            categoryResults = results
            phase = .preview(results: results)
        }
    }

    public func toggleCategory(_ category: CleanerCategory, selected: Bool) {
        guard let i = categoryResults.firstIndex(where: { $0.category == category }) else { return }
        categoryResults[i].isSelected = selected
    }

    public func cleanSelected() async {
        let toDelete = categoryResults.filter(\.isSelected).flatMap(\.items)
        guard !toDelete.isEmpty else { return }
        await MainActor.run { phase = .cleaning(progress: 0) }
        var freed: Int64 = 0
        var failures: [String] = []
        let fm = FileManager.default
        for (index, item) in toDelete.enumerated() {
            let (safe, _) = validator.isDeletionCandidateSafe(item.url, allowlistRoots: allowlist)
            guard safe else { continue }
            do {
                try fm.trashItem(at: item.url, resultingItemURL: nil)
                freed += item.sizeBytes
            } catch {
                let msg = "\(item.url.lastPathComponent): \(error.localizedDescription)"
                failures.append(msg)
                log.error("Trash failed \(item.url.path): \(error.localizedDescription)")
            }
            let progress = Double(index + 1) / Double(toDelete.count)
            await MainActor.run { phase = .cleaning(progress: progress) }
        }
        CleanerHistoryStore.shared.didFinishClean(freedBytes: freed, failures: failures)
        await MainActor.run { phase = .completed(freedBytes: freed) }
    }

    public func reset() {
        phase = .idle
        categoryResults = []
    }

    private func scanCategory(_ category: CleanerCategory) async -> [CleanerItem] {
        switch category {
        case .userTempFiles:
            return enumerate(url: URL(fileURLWithPath: NSTemporaryDirectory()), category: category, maxDepth: 6)
        case .userCaches:
            let root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches")
            return enumerate(url: root, category: category, maxDepth: 8, skipBrowser: true)
        case .appTempFiles:
            let root = URL(fileURLWithPath: "/private/var/folders")
            return enumerate(url: root, category: category, maxDepth: 10)
        case .diagnosticLogs:
            let root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs")
            return enumerate(url: root, category: category, maxDepth: 6, minAgeDays: 14)
        case .installerLeftovers:
            let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            return enumerate(url: tmp, category: category, maxDepth: 4, nameFilter: { $0.hasSuffix(".pkg") || $0.hasSuffix(".mpkg") })
        case .devCaches:
            let home = FileManager.default.homeDirectoryForCurrentUser
            let derived = home.appendingPathComponent("Library/Developer/Xcode/DerivedData")
            let spm = home.appendingPathComponent("Library/Caches/org.swift.swiftpm")
            return enumerate(url: derived, category: category, maxDepth: 4)
                + enumerate(url: spm, category: category, maxDepth: 6)
        }
    }

    private func enumerate(
        url: URL,
        category: CleanerCategory,
        maxDepth: Int,
        skipBrowser: Bool = false,
        minAgeDays: Int? = nil,
        nameFilter: ((String) -> Bool)? = nil
    ) -> [CleanerItem] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        var items: [CleanerItem] = []
        let cutoff = minAgeDays.map { Date().addingTimeInterval(-Double($0) * 86_400) }

        if let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) {
            for case let fileURL as URL in enumerator {
                let depth = fileURL.pathComponents.count - url.pathComponents.count
                if depth > maxDepth { enumerator.skipDescendants(); continue }
                if skipBrowser, SafetyValidator().isDeletionCandidateSafe(fileURL, allowlistRoots: allowlist).1 == "Browser profile area" {
                    enumerator.skipDescendants()
                    continue
                }
                guard let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey, .isSymbolicLinkKey]) else { continue }
                if values.isSymbolicLink == true { continue }
                guard values.isRegularFile == true else { continue }
                if let nameFilter, !nameFilter(fileURL.lastPathComponent) { continue }
                if let cutoff, let mod = values.contentModificationDate, mod > cutoff { continue }
                let size = Int64(values.fileSize ?? 0)
                guard size > 0 else { continue }
                let (safe, reason) = validator.isDeletionCandidateSafe(fileURL, allowlistRoots: allowlist)
                guard safe else { continue }
                items.append(CleanerItem(url: fileURL, category: category, sizeBytes: size, reason: reason))
            }
        }
        return items
    }
}
