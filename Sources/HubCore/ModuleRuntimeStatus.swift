import Foundation
import HubSettings

public struct ModuleRuntimeRow: Identifiable, Sendable {
    public let id: HubModuleID
    public let isEnabled: Bool
    public let isActive: Bool
    public let destination: HubDestination?

    public init(id: HubModuleID, isEnabled: Bool, isActive: Bool, destination: HubDestination?) {
        self.id = id
        self.isEnabled = isEnabled
        self.isActive = isActive
        self.destination = destination
    }

    public static func overviewRows(
        config: AppConfiguration,
        monitorRunning: Bool,
        islandRunning: Bool,
        deviceLockActive: Bool
    ) -> [ModuleRuntimeRow] {
        [
            ModuleRuntimeRow(
                id: .smartCleaner,
                isEnabled: config.isModuleEnabled(.smartCleaner),
                isActive: config.isModuleEnabled(.smartCleaner),
                destination: .smartCleaner
            ),
            ModuleRuntimeRow(
                id: .systemMonitor,
                isEnabled: config.isModuleEnabled(.systemMonitor),
                isActive: monitorRunning,
                destination: .systemMonitor
            ),
            ModuleRuntimeRow(
                id: .deviceControl,
                isEnabled: config.isModuleEnabled(.deviceControl),
                isActive: deviceLockActive,
                destination: .deviceControl
            ),
            ModuleRuntimeRow(
                id: .dynamicIsland,
                isEnabled: config.dynamicIslandEnabled,
                isActive: islandRunning,
                destination: .dynamicIsland
            ),
        ]
    }
}
