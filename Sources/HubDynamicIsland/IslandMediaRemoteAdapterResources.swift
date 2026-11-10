import Foundation

struct IslandMediaRemoteAdapterResources {
    let scriptURL: URL
    let frameworkURL: URL

    static func resolve(bundle: Bundle = Bundle.module) -> IslandMediaRemoteAdapterResources? {
        if let nested = resolveNested(in: bundle) { return nested }
        return resolveFlattened(in: bundle)
    }

    /// Xcode / preserved folder copy: `MediaRemoteAdapter/mediaremote-adapter.pl` + `.framework`.
    private static func resolveNested(in bundle: Bundle) -> IslandMediaRemoteAdapterResources? {
        let base = bundle.resourceURL?.appendingPathComponent("MediaRemoteAdapter")
            ?? bundle.url(forResource: "MediaRemoteAdapter", withExtension: nil)
        guard let base else { return nil }

        let scriptURL = base.appendingPathComponent("mediaremote-adapter.pl")
        let frameworkBundle = base.appendingPathComponent("MediaRemoteAdapter.framework")
        repairFrameworkLoadPath(frameworkBundle)
        let loadable = frameworkBundle.appendingPathComponent("MediaRemoteAdapter")
        guard FileManager.default.fileExists(atPath: scriptURL.path),
              FileManager.default.isReadableFile(atPath: loadable.path) else {
            return nil
        }
        return IslandMediaRemoteAdapterResources(scriptURL: scriptURL, frameworkURL: frameworkBundle)
    }

    /// SwiftPM `.process` flattens files into the bundle root — rebuild a loadable `.framework` on demand.
    private static func resolveFlattened(in bundle: Bundle) -> IslandMediaRemoteAdapterResources? {
        guard let resourceURL = bundle.resourceURL else { return nil }
        let scriptURL = resourceURL.appendingPathComponent("mediaremote-adapter.pl")
        let dylibURL = resourceURL.appendingPathComponent("MediaRemoteAdapter")
        guard FileManager.default.fileExists(atPath: scriptURL.path),
              FileManager.default.isReadableFile(atPath: dylibURL.path) else {
            return nil
        }
        let frameworkBundle = ensureLoadableFramework(near: resourceURL, dylibURL: dylibURL)
        guard FileManager.default.isReadableFile(atPath: frameworkBundle.appendingPathComponent("MediaRemoteAdapter").path) else {
            return nil
        }
        return IslandMediaRemoteAdapterResources(scriptURL: scriptURL, frameworkURL: frameworkBundle)
    }

    private static func ensureLoadableFramework(near base: URL, dylibURL: URL) -> URL {
        let frameworkBundle = base.appendingPathComponent("MediaRemoteAdapter.framework")
        let loadable = frameworkBundle.appendingPathComponent("MediaRemoteAdapter")
        if FileManager.default.isReadableFile(atPath: loadable.path) {
            return frameworkBundle
        }
        try? FileManager.default.createDirectory(at: frameworkBundle, withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: loadable)
        try? FileManager.default.createSymbolicLink(
            atPath: loadable.path,
            withDestinationPath: "../MediaRemoteAdapter"
        )
        return frameworkBundle
    }

    /// mediaremote-adapter.pl loads `Framework.framework/FrameworkName`; SwiftPM bundles often omit `Versions/Current`.
    private static func repairFrameworkLoadPath(_ frameworkBundle: URL) {
        let loadable = frameworkBundle.appendingPathComponent("MediaRemoteAdapter")
        if FileManager.default.isReadableFile(atPath: loadable.path) { return }
        let binary = frameworkBundle.appendingPathComponent("Versions/A/MediaRemoteAdapter")
        guard FileManager.default.isReadableFile(atPath: binary.path) else { return }
        try? FileManager.default.removeItem(at: loadable)
        try? FileManager.default.createSymbolicLink(
            atPath: loadable.path,
            withDestinationPath: "Versions/A/MediaRemoteAdapter"
        )
    }

    func streamArguments() -> [String] {
        [
            "/usr/bin/perl",
            scriptURL.path,
            frameworkURL.path,
            "stream",
            "--no-diff",
            "--debounce=50",
        ]
    }

    func sendCommandArguments(commandID: Int) -> [String] {
        [
            "/usr/bin/perl",
            scriptURL.path,
            frameworkURL.path,
            "send",
            String(commandID),
        ]
    }
}
