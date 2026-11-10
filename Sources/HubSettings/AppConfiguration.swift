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

}

// MARK: - Dynamic Island (forwarding to unified configuration)

extension AppConfiguration {
    private var island: DynamicIslandConfiguration { .shared }

    public var dynamicIslandEnabled: Bool {
        get { island.runtimeSnapshot.dynamicIslandEnabled }
        set { island.dynamicIslandEnabled = newValue }
    }

    public var islandDisplayMode: IslandDisplayMode {
        get { island.runtimeSnapshot.displayMode }
        set { island.islandDisplayMode = newValue }
    }

    public var islandDisplayID: CGDirectDisplayID? {
        get { island.runtimeSnapshot.displayID }
        set { island.islandDisplayID = newValue }
    }

    public var islandVerticalOffset: CGFloat {
        get { island.runtimeSnapshot.verticalOffset }
        set { island.islandVerticalOffset = newValue }
    }

    public var islandCompactHeight: CGFloat {
        get { island.runtimeSnapshot.compactHeight }
        set { island.islandCompactHeight = newValue }
    }

    public var islandExpandedHeight: CGFloat {
        get { island.runtimeSnapshot.expandedHeight }
        set { island.islandExpandedHeight = newValue }
    }

    public var islandExpandedWidth: CGFloat {
        get { island.runtimeSnapshot.expandedWidth }
        set { island.islandExpandedWidth = newValue }
    }

    public var islandBackgroundOpacity: Double {
        get { island.runtimeSnapshot.backgroundOpacity }
        set { island.islandBackgroundOpacity = newValue }
    }

    public var islandCornerRadius: CGFloat {
        get { island.runtimeSnapshot.cornerRadius }
        set { island.islandCornerRadius = newValue }
    }

    public var islandCompactWidth: CGFloat {
        get { island.runtimeSnapshot.compactWidth }
        set { island.islandCompactWidth = newValue }
    }

    public var islandAnimationDuration: TimeInterval {
        get { island.runtimeSnapshot.animationDuration }
        set { island.islandAnimationDuration = newValue }
    }

    public var islandAutoCollapseSeconds: TimeInterval {
        get { island.runtimeSnapshot.autoCollapseSeconds }
        set { island.islandAutoCollapseSeconds = newValue }
    }

    public var islandHoverExpands: Bool {
        get { island.runtimeSnapshot.hoverExpands }
        set { island.islandHoverExpands = newValue }
    }

    public var islandClickExpands: Bool {
        get { island.runtimeSnapshot.clickExpands }
        set { island.islandClickExpands = newValue }
    }

    public var islandHoverDelaySeconds: TimeInterval {
        get { island.runtimeSnapshot.hoverDelaySeconds }
        set { island.islandHoverDelaySeconds = newValue }
    }

    public var islandNotificationDurationSeconds: TimeInterval {
        get { island.runtimeSnapshot.notificationDurationSeconds }
        set { island.islandNotificationDurationSeconds = newValue }
    }

    public var islandNotificationDuration: TimeInterval {
        get { islandNotificationDurationSeconds }
        set { islandNotificationDurationSeconds = newValue }
    }

    public var islandMultiActivityEnabled: Bool {
        get { island.runtimeSnapshot.multiActivityEnabled }
        set { island.islandMultiActivityEnabled = newValue }
    }

    public var islandMaxCompactActivityIcons: Int {
        get { island.runtimeSnapshot.maxCompactActivityIcons }
        set { island.islandMaxCompactActivityIcons = newValue }
    }

    public var islandEventSystemMetricsEnabled: Bool {
        get { island.runtimeSnapshot.eventSystemMetricsEnabled }
        set { island.islandEventSystemMetricsEnabled = newValue }
    }

    public var islandEventMicrophoneEnabled: Bool {
        get { island.runtimeSnapshot.eventMicrophoneEnabled }
        set { island.islandEventMicrophoneEnabled = newValue }
    }

    public var islandEventCameraEnabled: Bool {
        get { island.runtimeSnapshot.eventCameraEnabled }
        set { island.islandEventCameraEnabled = newValue }
    }

    public var islandEventAudioDeviceEnabled: Bool {
        get { island.runtimeSnapshot.eventAudioDeviceEnabled }
        set { island.islandEventAudioDeviceEnabled = newValue }
    }

    public var islandEventMediaEnabled: Bool {
        get { island.runtimeSnapshot.eventMediaEnabled }
        set { island.islandEventMediaEnabled = newValue }
    }

    public var islandEventNotificationsEnabled: Bool {
        get { island.runtimeSnapshot.eventNotificationsEnabled }
        set { island.islandEventNotificationsEnabled = newValue }
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
