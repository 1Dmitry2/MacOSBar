import AppKit
import HubDeviceControl
import HubDynamicIsland
import HubSettings
import HubShortcuts
import HubSystemMonitor

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        migrateLegacyDefaultsIfNeeded()
        SystemMonitorService.shared.updateInterval = AppConfiguration.shared.monitorUpdateInterval
        SystemMonitorService.shared.start()
        _ = GlobalShortcutManager.shared
        _ = HubShortcutRouter.shared
        NSApp.setActivationPolicy(.regular)
        Task { @MainActor in
            let config = AppConfiguration.shared
            if config.dynamicIslandAutostart {
                config.dynamicIslandEnabled = true
                DynamicIslandConfiguration.shared.applyPendingChanges()
            }
            if config.dynamicIslandEnabled {
                DynamicIslandController.shared.startIfEnabled()
            }
            MonitorSidebarController.shared.applyConfiguration()
            MainWindowPresenter.open()
        }
    }

    /// `swift run` used identifier `MacOSHub`; bundled app uses `com.macoshub.app`.
    private func migrateLegacyDefaultsIfNeeded() {
        let legacy = UserDefaults(suiteName: "MacOSHub") ?? UserDefaults.standard
        let keys = legacy.dictionaryRepresentation().keys.filter { $0.hasPrefix("island.") || $0.hasPrefix("app.") || $0.hasPrefix("menubar.") || $0.hasPrefix("module.enabled.") }
        guard !keys.isEmpty else { return }
        let current = UserDefaults.standard
        let migratedKey = "com.macoshub.defaultsMigratedFromMacOSHub"
        guard !current.bool(forKey: migratedKey) else { return }
        for key in keys {
            current.set(legacy.object(forKey: key), forKey: key)
        }
        current.set(true, forKey: migratedKey)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !AppConfiguration.shared.runInBackground
    }

    func applicationWillTerminate(_ notification: Notification) {
        InputLockService.shared.unlockAll()
        DynamicIslandController.shared.stop()
        MonitorSidebarController.shared.stop()
        SystemMonitorService.shared.stop()
    }
}
