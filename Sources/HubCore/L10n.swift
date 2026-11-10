import Foundation
import HubSettings

public enum L10n {
    public static let bundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle.main
        #endif
    }()

    public static func tr(_ key: String, locale: Locale? = nil) -> String {
        let active = locale ?? AppConfiguration.shared.language.locale
        let code = active.language.languageCode?.identifier ?? "ru"

        if let lprojPath = bundle.path(forResource: code, ofType: "lproj"),
           let langBundle = Bundle(path: lprojPath) {
            let localized = langBundle.localizedString(forKey: key, value: nil, table: nil)
            if !localized.isEmpty, localized != key { return localized }
        }

        let fallback = bundle.localizedString(forKey: key, value: key, table: nil)
        if fallback != key { return fallback }

        // English fallback for incomplete RU tables
        if code != "en",
           let enPath = bundle.path(forResource: "en", ofType: "lproj"),
           let enBundle = Bundle(path: enPath) {
            let en = enBundle.localizedString(forKey: key, value: key, table: nil)
            if en != key { return en }
        }

        return key
    }
}
