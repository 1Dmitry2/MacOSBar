import AppKit
import HubCore

@MainActor
enum MainWindowPresenter {
    static func open(to destination: HubDestination? = nil) {
        if let destination {
            NavigationState.shared.selection = destination
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)

        let candidates = NSApp.windows.filter { $0.canBecomeMain && !$0.isMiniaturized }
        if let window = candidates.first {
            window.makeKeyAndOrderFront(nil)
            return
        }

        // WindowGroup may be hidden — reopen by toggling visibility on any app window or creating via notification.
        NotificationCenter.default.post(name: .hubOpenMainWindow, object: nil)
        for window in NSApp.windows where !window.isMiniaturized {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

extension Notification.Name {
    static let hubOpenMainWindow = Notification.Name("hub.openMainWindow")
}
