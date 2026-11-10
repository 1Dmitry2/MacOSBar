import AppKit
import Foundation

@MainActor
enum IslandInteractionSupport {
    static func activateForUserAction() {
        NSApp.activate(ignoringOtherApps: true)
        DynamicIslandController.shared.focusPanelIfNeeded()
    }
}
