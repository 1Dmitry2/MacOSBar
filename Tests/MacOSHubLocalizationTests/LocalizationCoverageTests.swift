import Foundation
import HubCleaner
import HubCore
import HubShortcuts
import Testing

@Test func navKeysResolveInRussian() {
    let locale = Locale(identifier: "ru_RU")
    let keys = HubDestination.allCases.map(\.localizationKey)
    for key in keys {
        let value = HubCore.L10n.tr(key, locale: locale)
        #expect(value != key, "Missing RU translation for \(key)")
    }
}

@Test func cleanerCategoryKeysResolveInRussian() {
    let locale = Locale(identifier: "ru_RU")
    for cat in CleanerCategory.allCases {
        #expect(HubCore.L10n.tr(cat.localizationKey, locale: locale) != cat.localizationKey)
        #expect(HubCore.L10n.tr(cat.summaryKey, locale: locale) != cat.summaryKey)
    }
}

@Test func shortcutKeysResolveInRussian() {
    let locale = Locale(identifier: "ru_RU")
    for action in ShortcutAction.allCases {
        let key = action.localizationKey
        #expect(HubCore.L10n.tr(key, locale: locale) != key)
    }
}

@Test func settingsGeneralResolves() {
    let ru = HubCore.L10n.tr("settings.general", locale: Locale(identifier: "ru_RU"))
    let en = HubCore.L10n.tr("settings.general", locale: Locale(identifier: "en_US"))
    #expect(ru == "Общие")
    #expect(en == "General")
}
