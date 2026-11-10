import SwiftUI

public enum HubTheme {
    public static let sidebarSelection = Color(red: 0.45, green: 0.35, blue: 0.95)
    public static let accentPurple = Color(red: 0.55, green: 0.45, blue: 1.0)
    public static let cardBackground = Color(nsColor: .controlBackgroundColor).opacity(0.6)
    public static let successGreen = Color(red: 0.2, green: 0.78, blue: 0.45)
    public static let cautionYellow = Color(red: 0.95, green: 0.75, blue: 0.2)
}

public struct HubCard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding()
            .background(HubTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}
