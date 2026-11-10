import Foundation

public struct SafetyValidator: Sendable {
    public init() {}

    private static let forbiddenPathComponents: Set<String> = [
        "Documents", "Desktop", "Downloads", "Pictures", "Movies", "Music",
        "Library/Messages", "Library/Mail", "Library/Photos", "Library/Safari",
        "Library/Application Support", "Library/Containers", "Library/Group Containers",
        "Library/Keychains", "Library/Autosave Information",
    ]

    private static let forbiddenSuffixes: Set<String> = [
        ".photoslibrary", ".dmg", ".backup", ".keychain-db", ".sqlite", ".db"
    ]

    private static let browserMarkers: [String] = [
        "Google/Chrome", "Firefox", "BraveSoftware", "Microsoft Edge", "Opera"
    ]

    public func isDeletionCandidateSafe(_ url: URL, allowlistRoots: [URL]) -> (Bool, String) {
        let path = url.standardizedFileURL.path
        let resolved = (try? url.resolvingSymlinksInPath())?.path ?? path

        if path != resolved {
            return (false, "Symbolic link target outside direct path")
        }

        for forbidden in Self.forbiddenPathComponents {
            if path.contains("/\(forbidden)/") || path.hasSuffix("/\(forbidden)") {
                return (false, "Protected user location")
            }
        }

        for marker in Self.browserMarkers {
            if path.contains(marker) {
                return (false, "Browser profile area")
            }
        }

        let lower = path.lowercased()
        for suffix in Self.forbiddenSuffixes {
            if lower.hasSuffix(suffix) {
                return (false, "Protected file type")
            }
        }

        if path.contains("Cookies") || path.contains("Login Data") || path.contains("Bookmarks") {
            return (false, "Browser session data")
        }

        guard allowlistRoots.contains(where: { root in
            path == root.path || path.hasPrefix(root.path + "/")
        }) else {
            return (false, "Outside allowlist")
        }

        return (true, "Regenerable cache or temp file in allowlisted scope")
    }

    public static func defaultAllowlist(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> [URL] {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
        return [
            tmp,
            home.appendingPathComponent("Library/Caches"),
            home.appendingPathComponent("Library/Logs"),
            URL(fileURLWithPath: "/private/var/folders"),
        ]
    }
}
