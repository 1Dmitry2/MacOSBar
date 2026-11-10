import AppKit
import CoreGraphics
import Foundation
import HubSettings

public enum HubDisplayResolver {
    public static func displayID(for screen: NSScreen) -> CGDirectDisplayID {
        guard
            let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        else { return 0 }
        return CGDirectDisplayID(number.uint32Value)
    }

    public static func isBuiltIn(_ screen: NSScreen) -> Bool {
        CGDisplayIsBuiltin(displayID(for: screen)) != 0
    }

    public static func screen(named localizedName: String) -> NSScreen? {
        NSScreen.screens.first { $0.localizedName == localizedName }
    }

    public static func builtInScreen() -> NSScreen? {
        NSScreen.screens.first { isBuiltIn($0) }
    }

    @MainActor
    public static func resolvedScreen(
        mode: IslandDisplayMode,
        displayID: CGDirectDisplayID?,
        fallbackBuiltIn: Bool = true
    ) -> NSScreen? {
        switch mode {
        case .builtIn:
            return builtInScreen() ?? NSScreen.main ?? NSScreen.screens.first
        case .mainDisplay:
            return NSScreen.main ?? NSScreen.screens.first
        case .specific:
            if let id = displayID,
               let match = NSScreen.screens.first(where: { HubDisplayResolver.displayID(for: $0) == id }) {
                return match
            }
            if fallbackBuiltIn { return builtInScreen() ?? NSScreen.main }
            return NSScreen.main
        }
    }

    @MainActor
    public static func resolvedIslandScreen() -> NSScreen? {
        let config = AppConfiguration.shared
        return resolvedScreen(mode: config.islandDisplayMode, displayID: config.islandDisplayID)
    }

    @MainActor
    public static func resolvedSidebarScreen() -> NSScreen? {
        let config = AppConfiguration.shared
        return resolvedScreen(mode: config.monitorSidebarDisplayMode, displayID: config.monitorSidebarDisplayID)
    }

    public static func availableScreens() -> [(id: CGDirectDisplayID, name: String, builtIn: Bool)] {
        NSScreen.screens.map { screen in
            let id = displayID(for: screen)
            return (id, screen.localizedName, isBuiltIn(screen))
        }
    }
}
