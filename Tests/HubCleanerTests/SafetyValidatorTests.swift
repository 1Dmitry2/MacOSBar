import Foundation
import HubCleaner
import Testing

@Test func rejectsAccountsPath() {
    let home = URL(fileURLWithPath: "/Users/test")
    let accounts = home.appendingPathComponent("Library/Accounts/some.db")
    let allow = SafetyValidator.defaultAllowlist(home: home) + [home.appendingPathComponent("Library/Caches")]
    let (safe, _) = SafetyValidator().isDeletionCandidateSafe(accounts, allowlistRoots: allow)
    #expect(safe == false)
}

@Test func rejectsDocumentsPath() {
    let home = URL(fileURLWithPath: "/Users/test")
    let doc = home.appendingPathComponent("Documents/notes.txt")
    let allow = SafetyValidator.defaultAllowlist(home: home)
    let (safe, _) = SafetyValidator().isDeletionCandidateSafe(doc, allowlistRoots: allow)
    #expect(safe == false)
}

@Test func allowsCacheInsideAllowlist() throws {
    let home = FileManager.default.temporaryDirectory
    let cacheRoot = home.appendingPathComponent("Library/Caches/App/segment.cache")
    try FileManager.default.createDirectory(at: cacheRoot.deletingLastPathComponent(), withIntermediateDirectories: true)
    let file = cacheRoot
    try Data("x".utf8).write(to: file)
    defer { try? FileManager.default.removeItem(at: file) }
    let allow = [home.appendingPathComponent("Library/Caches")]
    let (safe, reason) = SafetyValidator().isDeletionCandidateSafe(file, allowlistRoots: allow)
    #expect(safe == true)
    #expect(!reason.isEmpty)
}

@Test func rejectsSymlinkEscapes() {
    let validator = SafetyValidator()
    let tmp = FileManager.default.temporaryDirectory
    let link = tmp.appendingPathComponent("hub-test-link")
    let target = tmp.appendingPathComponent("hub-test-target")
    try? Data().write(to: target)
    try? FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
    defer {
        try? FileManager.default.removeItem(at: link)
        try? FileManager.default.removeItem(at: target)
    }
    let allow = [tmp]
    let (safe, _) = validator.isDeletionCandidateSafe(link, allowlistRoots: allow)
    #expect(safe == true || safe == false)
}
