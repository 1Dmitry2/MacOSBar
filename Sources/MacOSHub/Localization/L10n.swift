import Foundation
import HubSettings
import SwiftUI

/// SPM executable strings live in `Bundle.module`, not `Bundle.main`.
enum L10n {
    static let bundle = Bundle.module

    static func tr(_ key: String, locale: Locale? = nil) -> String {
        let active = locale ?? AppConfiguration.shared.language.locale
        let resolved = String(
            localized: String.LocalizationValue(key),
            bundle: bundle,
            locale: active
        )
        if resolved != key { return resolved }
        // Fallback to Russian source catalog if lookup failed.
        let ru = String(
            localized: String.LocalizationValue(key),
            bundle: bundle,
            locale: Locale(identifier: "ru_RU")
        )
        if ru != key { return ru }
        #if DEBUG
        DiagnosticsStoreFallback.logMissing(key)
        #endif
        return ru
    }

    static func allKeysPresent(_ keys: [String], locale: Locale) -> [String] {
        keys.filter { tr($0, locale: locale) == $0 }
    }
}

/// Lightweight `Text` bound to the string catalog in `Bundle.module`.
struct LText: View {
    let key: String
    @Environment(\.locale) private var locale

    init(_ key: String) {
        self.key = key
    }

    var body: some View {
        Text(L10n.tr(key, locale: locale))
    }
}

#if DEBUG
enum DiagnosticsStoreFallback {
    static func logMissing(_ key: String) {
        print("[L10n] Missing translation for key: \(key)")
    }
}
#endif

private struct LocalizationBundleKey: EnvironmentKey {
    static let defaultValue = Bundle.module
}

extension EnvironmentValues {
    var localizationBundle: Bundle {
        get { self[LocalizationBundleKey.self] }
        set { self[LocalizationBundleKey.self] = newValue }
    }
}
