import CoreGraphics
import Foundation
import Observation

public enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case ru
    case en

    public var locale: Locale {
        switch self {
        case .ru: return Locale(identifier: "ru_RU")
        case .en: return Locale(identifier: "en_US")
        }
    }

    public var displayName: String {
        switch self {
        case .ru: return "Русский"
        case .en: return "English"
        }
    }
}

public enum AppTheme: String, Codable, CaseIterable, Sendable {
    case system, light, dark
}

public enum CloseWindowBehavior: String, Codable, CaseIterable, Sendable {
    case hideToBackground
    case quit
}

public enum IslandDisplayMode: String, Codable, CaseIterable, Sendable {
    case builtIn
    case mainDisplay
    case specific
}

public enum MonitorSidebarEdge: String, Codable, CaseIterable, Sendable {
    case left
    case right
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
        static let menuBarDisk = "menubar.disk"
        static let menuBarTemp = "menubar.temp"
        static let islandEnabled = "island.enabled"
        static let islandDisplayMode = "island.displayMode"
        static let islandDisplayID = "island.displayID"
        static let islandVerticalOffset = "island.verticalOffset"
        static let islandWidgetPrefix = "island.widget."
        static let sidebarMonitor = "sidebar.monitor.enabled"
        static let sidebarEdge = "sidebar.monitor.edge"
        static let sidebarWidth = "sidebar.monitor.width"
        static let sidebarPinned = "sidebar.monitor.pinned"
        static let sidebarDisplayMode = "sidebar.monitor.displayMode"
        static let sidebarDisplayID = "sidebar.monitor.displayID"
        static let deviceAutoUnlockSeconds = "device.autoUnlockSeconds"
        static let language = "app.language"
        static let islandAutostart = "island.autostart"
    }

    public var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }

    public var dynamicIslandAutostart: Bool {
        didSet { defaults.set(dynamicIslandAutostart, forKey: Keys.islandAutostart) }
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

    public var menuBarShowsDisk: Bool {
        didSet { defaults.set(menuBarShowsDisk, forKey: Keys.menuBarDisk) }
    }

    public var menuBarShowsTemperature: Bool {
        didSet { defaults.set(menuBarShowsTemperature, forKey: Keys.menuBarTemp) }
    }

    public var dynamicIslandEnabled: Bool {
        didSet { defaults.set(dynamicIslandEnabled, forKey: Keys.islandEnabled) }
    }

    public var islandDisplayMode: IslandDisplayMode {
        didSet { defaults.set(islandDisplayMode.rawValue, forKey: Keys.islandDisplayMode) }
    }

    public var islandDisplayID: CGDirectDisplayID? {
        didSet {
            if let id = islandDisplayID {
                defaults.set(Int(id), forKey: Keys.islandDisplayID)
            } else {
                defaults.removeObject(forKey: Keys.islandDisplayID)
            }
        }
    }

    public var islandVerticalOffset: CGFloat {
        didSet { defaults.set(Double(islandVerticalOffset), forKey: Keys.islandVerticalOffset) }
    }

    public var monitorSidebarEnabled: Bool {
        didSet { defaults.set(monitorSidebarEnabled, forKey: Keys.sidebarMonitor) }
    }

    public var monitorSidebarEdge: MonitorSidebarEdge {
        didSet { defaults.set(monitorSidebarEdge.rawValue, forKey: Keys.sidebarEdge) }
    }

    public var monitorSidebarWidth: CGFloat {
        didSet { defaults.set(Double(monitorSidebarWidth), forKey: Keys.sidebarWidth) }
    }

    public var monitorSidebarPinned: Bool {
        didSet { defaults.set(monitorSidebarPinned, forKey: Keys.sidebarPinned) }
    }

    public var monitorSidebarDisplayMode: IslandDisplayMode {
        didSet { defaults.set(monitorSidebarDisplayMode.rawValue, forKey: Keys.sidebarDisplayMode) }
    }

    public var monitorSidebarDisplayID: CGDirectDisplayID? {
        didSet {
            if let id = monitorSidebarDisplayID {
                defaults.set(Int(id), forKey: Keys.sidebarDisplayID)
            } else {
                defaults.removeObject(forKey: Keys.sidebarDisplayID)
            }
        }
    }

    public var islandWidgetShowsCPU: Bool {
        get { widgetFlag("cpu", default: true) }
        set { setWidgetFlag("cpu", newValue) }
    }

    public var islandWidgetShowsRAM: Bool {
        get { widgetFlag("ram", default: true) }
        set { setWidgetFlag("ram", newValue) }
    }

    public var islandWidgetShowsDisk: Bool {
        get { widgetFlag("disk", default: false) }
        set { setWidgetFlag("disk", newValue) }
    }

    public var islandWidgetShowsBattery: Bool {
        get { widgetFlag("battery", default: true) }
        set { setWidgetFlag("battery", newValue) }
    }

    public var islandWidgetShowsTime: Bool {
        get { widgetFlag("time", default: true) }
        set { setWidgetFlag("time", newValue) }
    }

    public var islandWidgetShowsDate: Bool {
        get { widgetFlag("date", default: true) }
        set { setWidgetFlag("date", newValue) }
    }

    public var islandWidgetShowsNetwork: Bool {
        get { widgetFlag("network", default: false) }
        set { setWidgetFlag("network", newValue) }
    }

    public var islandWidgetShowsTemperature: Bool {
        get { widgetFlag("temp", default: false) }
        set { setWidgetFlag("temp", newValue) }
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
        menuBarShowsDisk = defaults.object(forKey: Keys.menuBarDisk) as? Bool ?? false
        menuBarShowsTemperature = defaults.object(forKey: Keys.menuBarTemp) as? Bool ?? false
        dynamicIslandEnabled = defaults.object(forKey: Keys.islandEnabled) as? Bool ?? false
        let islandMode = defaults.string(forKey: Keys.islandDisplayMode) ?? IslandDisplayMode.builtIn.rawValue
        islandDisplayMode = IslandDisplayMode(rawValue: islandMode) ?? .builtIn
        if let storedID = defaults.object(forKey: Keys.islandDisplayID) as? Int {
            islandDisplayID = CGDirectDisplayID(storedID)
        } else {
            islandDisplayID = nil
        }
        islandVerticalOffset = CGFloat(defaults.object(forKey: Keys.islandVerticalOffset) as? Double ?? 0)
        monitorSidebarEnabled = defaults.object(forKey: Keys.sidebarMonitor) as? Bool ?? false
        let edgeRaw = defaults.string(forKey: Keys.sidebarEdge) ?? MonitorSidebarEdge.right.rawValue
        monitorSidebarEdge = MonitorSidebarEdge(rawValue: edgeRaw) ?? .right
        monitorSidebarWidth = CGFloat(defaults.object(forKey: Keys.sidebarWidth) as? Double ?? 280)
        monitorSidebarPinned = defaults.object(forKey: Keys.sidebarPinned) as? Bool ?? true
        let sidebarMode = defaults.string(forKey: Keys.sidebarDisplayMode) ?? IslandDisplayMode.builtIn.rawValue
        monitorSidebarDisplayMode = IslandDisplayMode(rawValue: sidebarMode) ?? .builtIn
        if let storedSidebar = defaults.object(forKey: Keys.sidebarDisplayID) as? Int {
            monitorSidebarDisplayID = CGDirectDisplayID(storedSidebar)
        } else {
            monitorSidebarDisplayID = nil
        }
        deviceAutoUnlockSeconds = defaults.object(forKey: Keys.deviceAutoUnlockSeconds) as? Int ?? 300
        let langRaw = defaults.string(forKey: Keys.language) ?? AppLanguage.ru.rawValue
        language = AppLanguage(rawValue: langRaw) ?? .ru
        dynamicIslandAutostart = defaults.object(forKey: Keys.islandAutostart) as? Bool ?? false
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

    private func widgetFlag(_ name: String, default defaultValue: Bool) -> Bool {
        let key = Keys.islandWidgetPrefix + name
        if defaults.object(forKey: key) == nil { return defaultValue }
        return defaults.bool(forKey: key)
    }

    private func setWidgetFlag(_ name: String, _ value: Bool) {
        defaults.set(value, forKey: Keys.islandWidgetPrefix + name)
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
