import AppKit
import HubDeviceControl
import HubDynamicIsland
import HubSettings
import HubShortcuts
import HubSystemMonitor

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        SystemMonitorService.shared.updateInterval = AppConfiguration.shared.monitorUpdateInterval
        SystemMonitorService.shared.start()
        _ = GlobalShortcutManager.shared
        _ = HubShortcutRouter.shared
        Task { @MainActor in
            if AppConfiguration.shared.dynamicIslandEnabled {
                DynamicIslandController.shared.startIfEnabled()
            }
            MonitorSidebarController.shared.applyConfiguration()
        }
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
