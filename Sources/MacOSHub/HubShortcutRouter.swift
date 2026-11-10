import AppKit
import HubCleaner
import HubCore
import HubDynamicIsland
import HubSettings
import HubShortcuts
import HubSystemMonitor

@MainActor
final class HubShortcutRouter {
    static let shared = HubShortcutRouter()

    private init() {
        NotificationCenter.default.addObserver(
            forName: .hubShortcutTriggered,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let action = note.object as? ShortcutAction else { return }
            Task { @MainActor in self?.handle(action) }
        }
    }

    func handle(_ action: ShortcutAction) {
        let navigation = NavigationState.shared
        switch action {
        case .toggleApp:
            toggleMainWindow()
        case .openSmartCleaner:
            navigation.selection = .smartCleaner
            showMain()
        case .startCleanerScan:
            navigation.selection = .smartCleaner
            showMain()
            Task { await CleanerEngine.shared.scan(categories: Set(CleanerCategory.allCases)) }
        case .openSystemMonitor:
            navigation.selection = .systemMonitor
            showMain()
        case .toggleMonitorSidebar:
            MonitorSidebarController.shared.toggle()
        case .toggleDynamicIsland:
            AppConfiguration.shared.dynamicIslandEnabled.toggle()
            DynamicIslandController.shared.applySettingsChange()
        case .toggleIslandExpanded:
            DynamicIslandController.shared.toggleExpanded()
        case .openDeviceControl:
            navigation.selection = .deviceControl
            showMain()
        }
    }

    private func toggleMainWindow() {
        let app = NSApplication.shared
        if app.isHidden || app.windows.allSatisfy({ !$0.isVisible }) {
            showMain()
        } else {
            app.windows.forEach { $0.orderOut(nil) }
        }
    }

    private func showMain() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.canBecomeMain {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
