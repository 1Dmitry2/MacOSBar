import SwiftUI

/// Ensures alerts/sheets inherit the app color scheme and readable materials.
struct HubDialogChrome: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.colorScheme, colorScheme)
    }
}

extension View {
    func hubDialogChrome() -> some View {
        modifier(HubDialogChrome())
    }
}
