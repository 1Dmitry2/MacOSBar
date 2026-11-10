import HubSettings
import SwiftUI

/// RGB tints from island settings (0…1 per channel).
public struct IslandChromeColors: Equatable, Sendable {
    public var background: Color
    public var accent: Color
    public var foreground: Color

    public init(background: Color, accent: Color, foreground: Color) {
        self.background = background
        self.accent = accent
        self.foreground = foreground
    }

    public static func from(snapshot: DynamicIslandSettingsSnapshot) -> IslandChromeColors {
        IslandChromeColors(
            background: color(
                red: snapshot.chromeRed,
                green: snapshot.chromeGreen,
                blue: snapshot.chromeBlue
            ),
            accent: color(
                red: snapshot.accentRed,
                green: snapshot.accentGreen,
                blue: snapshot.accentBlue
            ),
            foreground: color(
                red: snapshot.foregroundRed,
                green: snapshot.foregroundGreen,
                blue: snapshot.foregroundBlue
            )
        )
    }

    private static func color(red: Double, green: Double, blue: Double) -> Color {
        Color(red: red, green: green, blue: blue)
    }
}
