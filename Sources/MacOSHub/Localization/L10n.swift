import HubCore
import SwiftUI

typealias L10n = HubCore.L10n

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
