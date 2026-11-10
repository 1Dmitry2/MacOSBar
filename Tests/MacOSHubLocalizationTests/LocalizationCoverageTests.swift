import Foundation
import HubCore
import Testing

@Test func navKeysResolveInRussian() {
    let locale = Locale(identifier: "ru_RU")
    let keys = HubDestination.allCases.map(\.localizationKey)
    for key in keys {
        let value = HubCore.L10n.tr(key, locale: locale)
        #expect(value != key, "Missing RU translation for \(key)")
    }
}

@Test func settingsGeneralResolves() {
    let ru = HubCore.L10n.tr("settings.general", locale: Locale(identifier: "ru_RU"))
    let en = HubCore.L10n.tr("settings.general", locale: Locale(identifier: "en_US"))
    #expect(ru == "Общие")
    #expect(en == "General")
}
