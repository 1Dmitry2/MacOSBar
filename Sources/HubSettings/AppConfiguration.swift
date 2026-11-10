import Foundation
import Observation

public enum AppTheme: String, Codable, CaseIterable, Sendable {
    case system, light, dark
}

public enum CloseWindowBehavior: String, Codable, CaseIterable, Sendable {
    case hideToBackground
    case quit
}

@Observable
public final class AppConfiguration: @unchecked Sendable {
    public static let shared = AppConfiguration()

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let launchAtLogin = "launchAtLogin"
        static let runInBackground = "runInBackground"
        static let theme = "theme"
        static let closeBehavior = "closeBehavior"
        static let modulePrefix = "module.enabled."
        static let monitorInterval = "monitor.interval"
        static let menuBarCPU = "menubar.cpu"
        static let menuBarRAM = "menubar.ram"
        static let islandEnabled = "island.enabled"
        static let deviceAutoUnlockSeconds = "device.autoUnlockSeconds"
    }

    public var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    public var runInBackground: Bool {
        didSet { defaults.set(runInBackground, forKey: Keys.runInBackground) }
    }

    public var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }

    public var closeWindowBehavior: CloseWindowBehavior {
        didSet { defaults.set(closeWindowBehavior.rawValue, forKey: Keys.closeBehavior) }
    }

    public var monitorUpdateInterval: TimeInterval {
        didSet { defaults.set(monitorUpdateInterval, forKey: Keys.monitorInterval) }
    }

    public var menuBarShowsCPU: Bool {
        didSet { defaults.set(menuBarShowsCPU, forKey: Keys.menuBarCPU) }
    }

    public var menuBarShowsRAM: Bool {
        didSet { defaults.set(menuBarShowsRAM, forKey: Keys.menuBarRAM) }
    }

    public var dynamicIslandEnabled: Bool {
        didSet { defaults.set(dynamicIslandEnabled, forKey: Keys.islandEnabled) }
    }

    public var deviceAutoUnlockSeconds: Int {
        didSet { defaults.set(deviceAutoUnlockSeconds, forKey: Keys.deviceAutoUnlockSeconds) }
    }

  private init() {
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        runInBackground = defaults.object(forKey: Keys.runInBackground) as? Bool ?? true
        let themeRaw = defaults.string(forKey: Keys.theme) ?? AppTheme.dark.rawValue
        theme = AppTheme(rawValue: themeRaw) ?? .dark
        let closeRaw = defaults.string(forKey: Keys.closeBehavior) ?? CloseWindowBehavior.hideToBackground.rawValue
        closeWindowBehavior = CloseWindowBehavior(rawValue: closeRaw) ?? .hideToBackground
        monitorUpdateInterval = defaults.object(forKey: Keys.monitorInterval) as? TimeInterval ?? 2.0
        menuBarShowsCPU = defaults.object(forKey: Keys.menuBarCPU) as? Bool ?? true
        menuBarShowsRAM = defaults.object(forKey: Keys.menuBarRAM) as? Bool ?? false
        dynamicIslandEnabled = defaults.object(forKey: Keys.islandEnabled) as? Bool ?? false
        deviceAutoUnlockSeconds = defaults.object(forKey: Keys.deviceAutoUnlockSeconds) as? Int ?? 300
    }

    public func isModuleEnabled(_ id: HubModuleID) -> Bool {
        if defaults.object(forKey: Keys.modulePrefix + id.rawValue) == nil {
            return id.defaultEnabled
        }
        return defaults.bool(forKey: Keys.modulePrefix + id.rawValue)
    }

    public func setModuleEnabled(_ id: HubModuleID, enabled: Bool) {
        defaults.set(enabled, forKey: Keys.modulePrefix + id.rawValue)
    }
}

public enum HubModuleID: String, CaseIterable, Codable, Sendable, Identifiable {
    case smartCleaner
    case systemMonitor
    case deviceControl
    case dynamicIsland
    case diagnostics

    public var id: String { rawValue }

    public var defaultEnabled: Bool {
        switch self {
        case .smartCleaner, .systemMonitor: return true
        case .deviceControl, .dynamicIsland, .diagnostics: return false
        }
    }

    public var displayName: String {
        switch self {
        case .smartCleaner: return "Smart Cleaner"
        case .systemMonitor: return "System Monitor"
        case .deviceControl: return "Device Control"
        case .dynamicIsland: return "Dynamic Island"
        case .diagnostics: return "Diagnostics"
        }
    }
}
