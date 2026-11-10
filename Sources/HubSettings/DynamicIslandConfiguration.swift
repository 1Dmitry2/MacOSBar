import CoreGraphics
import Foundation
import Observation

/// RGB helper for settings UI (SwiftUI `Color` is not persisted).
public struct ColorComponents: Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

/// Persisted island settings (applied to the live panel when committed).
public struct DynamicIslandSettingsSnapshot: Codable, Equatable, Sendable {
    public var dynamicIslandEnabled: Bool
    public var displayMode: IslandDisplayMode
    public var displayID: CGDirectDisplayID?
    public var verticalOffset: CGFloat

    public var compactHeight: CGFloat
    public var expandedHeight: CGFloat
    public var expandedWidth: CGFloat
    public var backgroundOpacity: Double
    public var liquidGlassEnabled: Bool
    /// Dark tint on top of material (lower = more wallpaper visible).
    public var liquidGlassTintOpacity: Double
    public var cornerRadius: CGFloat
    public var chromeRed: Double
    public var chromeGreen: Double
    public var chromeBlue: Double
    public var accentRed: Double
    public var accentGreen: Double
    public var accentBlue: Double
    public var foregroundRed: Double
    public var foregroundGreen: Double
    public var foregroundBlue: Double
    public var compactWidth: CGFloat
    public var animationDuration: TimeInterval

    public var autoCollapseSeconds: TimeInterval
    public var hoverExpands: Bool
    public var clickExpands: Bool
    public var hoverDelaySeconds: TimeInterval
    public var notificationDurationSeconds: TimeInterval

    public var multiActivityEnabled: Bool
    public var maxCompactActivityIcons: Int

    public var eventSystemMetricsEnabled: Bool
    public var eventMicrophoneEnabled: Bool
    public var eventCameraEnabled: Bool
    public var eventAudioDeviceEnabled: Bool
    public var eventMediaEnabled: Bool
    /// When true, a new track briefly expands / flashes the island (off by default).
    public var mediaExpandOnTrackChange: Bool
    public var eventNotificationsEnabled: Bool

    public var widgetShowsCPU: Bool
    public var widgetShowsRAM: Bool
    public var widgetShowsDisk: Bool
    public var widgetShowsBattery: Bool
    public var widgetShowsTime: Bool
    public var widgetShowsDate: Bool
    public var widgetShowsNetwork: Bool
    public var widgetShowsTemperature: Bool
    public var widgetShowsMusic: Bool
    public var widgetOrder: [String]

    public static let defaultWidgetOrder = ["cpu", "ram", "temp", "disk", "battery", "time", "date", "network", "music"]

    public static var defaults: DynamicIslandSettingsSnapshot {
        DynamicIslandSettingsSnapshot(
            dynamicIslandEnabled: false,
            displayMode: .builtIn,
            displayID: nil,
            verticalOffset: 0,
            compactHeight: 32,
            expandedHeight: 292,
            expandedWidth: 620,
            backgroundOpacity: 0.92,
            liquidGlassEnabled: true,
            liquidGlassTintOpacity: 0.24,
            cornerRadius: 20,
            chromeRed: 0,
            chromeGreen: 0,
            chromeBlue: 0,
            accentRed: 0.55,
            accentGreen: 0.45,
            accentBlue: 1.0,
            foregroundRed: 1,
            foregroundGreen: 1,
            foregroundBlue: 1,
            compactWidth: 240,
            animationDuration: 0.32,
            autoCollapseSeconds: 0,
            hoverExpands: true,
            clickExpands: true,
            hoverDelaySeconds: 0.18,
            notificationDurationSeconds: 4,
            multiActivityEnabled: true,
            maxCompactActivityIcons: 3,
            eventSystemMetricsEnabled: true,
            eventMicrophoneEnabled: true,
            eventCameraEnabled: false,
            eventAudioDeviceEnabled: true,
            eventMediaEnabled: true,
            mediaExpandOnTrackChange: false,
            eventNotificationsEnabled: false,
            widgetShowsCPU: true,
            widgetShowsRAM: true,
            widgetShowsDisk: false,
            widgetShowsBattery: true,
            widgetShowsTime: true,
            widgetShowsDate: true,
            widgetShowsNetwork: false,
            widgetShowsTemperature: false,
            widgetShowsMusic: true,
            widgetOrder: defaultWidgetOrder
        )
    }

    public mutating func resetAppearanceToDefaults() {
        let d = Self.defaults
        backgroundOpacity = d.backgroundOpacity
        liquidGlassEnabled = d.liquidGlassEnabled
        liquidGlassTintOpacity = d.liquidGlassTintOpacity
        cornerRadius = d.cornerRadius
        chromeRed = d.chromeRed
        chromeGreen = d.chromeGreen
        chromeBlue = d.chromeBlue
        accentRed = d.accentRed
        accentGreen = d.accentGreen
        accentBlue = d.accentBlue
        foregroundRed = d.foregroundRed
        foregroundGreen = d.foregroundGreen
        foregroundBlue = d.foregroundBlue
        compactHeight = d.compactHeight
        expandedHeight = d.expandedHeight
        expandedWidth = d.expandedWidth
        compactWidth = d.compactWidth
        animationDuration = d.animationDuration
    }
}

/// Single source of truth for Dynamic Island settings, preview draft, and persistence.
@Observable
public final class DynamicIslandConfiguration: @unchecked Sendable {
    public static let shared = DynamicIslandConfiguration()

    public enum Notifications {
        public static let draftDidChange = Notification.Name("DynamicIslandConfiguration.draftDidChange")
        public static let appliedDidChange = Notification.Name("DynamicIslandConfiguration.appliedDidChange")
    }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let liveApply = "island.settings.liveApply"
        static let islandEnabled = "island.enabled"
        static let islandDisplayMode = "island.displayMode"
        static let islandDisplayID = "island.displayID"
        static let islandVerticalOffset = "island.verticalOffset"
        static let islandCompactHeight = "island.compactHeight"
        static let islandExpandedHeight = "island.expandedHeight"
        static let islandExpandedWidth = "island.expandedWidth"
        static let islandBackgroundOpacity = "island.backgroundOpacity"
        static let islandLiquidGlass = "island.liquidGlass"
        static let islandLiquidGlassTint = "island.liquidGlassTint"
        static let islandCornerRadius = "island.cornerRadius"
        static let islandChromeRed = "island.chromeRed"
        static let islandChromeGreen = "island.chromeGreen"
        static let islandChromeBlue = "island.chromeBlue"
        static let islandAccentRed = "island.accentRed"
        static let islandAccentGreen = "island.accentGreen"
        static let islandAccentBlue = "island.accentBlue"
        static let islandForegroundRed = "island.foregroundRed"
        static let islandForegroundGreen = "island.foregroundGreen"
        static let islandForegroundBlue = "island.foregroundBlue"
        static let islandCompactWidth = "island.compactWidth"
        static let islandAnimationDuration = "island.animationDuration"
        static let islandAutoCollapse = "island.autoCollapseSeconds"
        static let islandHoverExpands = "island.hoverExpands"
        static let islandClickExpands = "island.clickExpands"
        static let islandHoverDelay = "island.hoverDelaySeconds"
        static let islandNotificationDuration = "island.notificationDurationSeconds"
        static let islandMultiActivity = "island.multiActivity"
        static let islandMaxCompactIcons = "island.maxCompactActivityIcons"
        static let islandWidgetPrefix = "island.widget."
        static let islandMediaExpandOnTrackChange = "island.media.expandOnTrackChange"
        static let islandEventPrefix = "island.event."
        static let islandWidgetOrder = "island.widget.order"
    }

    public private(set) var appliedSnapshot: DynamicIslandSettingsSnapshot
    public var draftSnapshot: DynamicIslandSettingsSnapshot {
        didSet {
            if liveApplyEnabled {
                commitDraftToApplied()
            } else {
                pendingChanges = draftSnapshot != appliedSnapshot
            }
            NotificationCenter.default.post(name: Notifications.draftDidChange, object: self)
        }
    }

    public var liveApplyEnabled: Bool {
        didSet {
            defaults.set(liveApplyEnabled, forKey: Keys.liveApply)
            if liveApplyEnabled {
                commitDraftToApplied()
            } else {
                pendingChanges = draftSnapshot != appliedSnapshot
            }
        }
    }

    public private(set) var pendingChanges = false

    private init() {
        liveApplyEnabled = defaults.object(forKey: Keys.liveApply) as? Bool ?? true
        let loaded = Self.loadSnapshot(from: defaults)
        appliedSnapshot = loaded
        draftSnapshot = loaded
    }

    // MARK: - Draft accessors (settings UI + preview)

    public var dynamicIslandEnabled: Bool {
        get { draftSnapshot.dynamicIslandEnabled }
        set { mutateDraft { $0.dynamicIslandEnabled = newValue } }
    }

    public var islandDisplayMode: IslandDisplayMode {
        get { draftSnapshot.displayMode }
        set { mutateDraft { $0.displayMode = newValue } }
    }

    public var islandDisplayID: CGDirectDisplayID? {
        get { draftSnapshot.displayID }
        set { mutateDraft { $0.displayID = newValue } }
    }

    public var islandVerticalOffset: CGFloat {
        get { draftSnapshot.verticalOffset }
        set { mutateDraft { $0.verticalOffset = newValue } }
    }

    public var islandCompactHeight: CGFloat {
        get { draftSnapshot.compactHeight }
        set { mutateDraft { $0.compactHeight = newValue } }
    }

    public var islandExpandedHeight: CGFloat {
        get { draftSnapshot.expandedHeight }
        set { mutateDraft { $0.expandedHeight = newValue } }
    }

    public var islandExpandedWidth: CGFloat {
        get { draftSnapshot.expandedWidth }
        set { mutateDraft { $0.expandedWidth = newValue } }
    }

    public var islandBackgroundOpacity: Double {
        get { draftSnapshot.backgroundOpacity }
        set { mutateDraft { $0.backgroundOpacity = newValue } }
    }

    public var islandLiquidGlassEnabled: Bool {
        get { draftSnapshot.liquidGlassEnabled }
        set { mutateDraft { $0.liquidGlassEnabled = newValue } }
    }

    public var islandLiquidGlassTintOpacity: Double {
        get { draftSnapshot.liquidGlassTintOpacity }
        set { mutateDraft { $0.liquidGlassTintOpacity = newValue } }
    }

    public var islandCornerRadius: CGFloat {
        get { draftSnapshot.cornerRadius }
        set { mutateDraft { $0.cornerRadius = newValue } }
    }

    public var islandChromeColor: ColorComponents {
        get {
            ColorComponents(
                red: draftSnapshot.chromeRed,
                green: draftSnapshot.chromeGreen,
                blue: draftSnapshot.chromeBlue
            )
        }
        set { mutateDraft {
            $0.chromeRed = newValue.red
            $0.chromeGreen = newValue.green
            $0.chromeBlue = newValue.blue
        }}
    }

    public var islandAccentColor: ColorComponents {
        get {
            ColorComponents(
                red: draftSnapshot.accentRed,
                green: draftSnapshot.accentGreen,
                blue: draftSnapshot.accentBlue
            )
        }
        set { mutateDraft {
            $0.accentRed = newValue.red
            $0.accentGreen = newValue.green
            $0.accentBlue = newValue.blue
        }}
    }

    public var islandForegroundColor: ColorComponents {
        get {
            ColorComponents(
                red: draftSnapshot.foregroundRed,
                green: draftSnapshot.foregroundGreen,
                blue: draftSnapshot.foregroundBlue
            )
        }
        set { mutateDraft {
            $0.foregroundRed = newValue.red
            $0.foregroundGreen = newValue.green
            $0.foregroundBlue = newValue.blue
        }}
    }

    public var islandCompactWidth: CGFloat {
        get { draftSnapshot.compactWidth }
        set { mutateDraft { $0.compactWidth = newValue } }
    }

    public var islandAnimationDuration: TimeInterval {
        get { draftSnapshot.animationDuration }
        set { mutateDraft { $0.animationDuration = newValue } }
    }

    public var islandAutoCollapseSeconds: TimeInterval {
        get { draftSnapshot.autoCollapseSeconds }
        set { mutateDraft { $0.autoCollapseSeconds = newValue } }
    }

    public var islandHoverExpands: Bool {
        get { draftSnapshot.hoverExpands }
        set { mutateDraft { $0.hoverExpands = newValue } }
    }

    public var islandClickExpands: Bool {
        get { draftSnapshot.clickExpands }
        set { mutateDraft { $0.clickExpands = newValue } }
    }

    public var islandHoverDelaySeconds: TimeInterval {
        get { draftSnapshot.hoverDelaySeconds }
        set { mutateDraft { $0.hoverDelaySeconds = newValue } }
    }

    public var islandNotificationDurationSeconds: TimeInterval {
        get { draftSnapshot.notificationDurationSeconds }
        set { mutateDraft { $0.notificationDurationSeconds = newValue } }
    }

    public var islandNotificationDuration: TimeInterval {
        get { islandNotificationDurationSeconds }
        set { islandNotificationDurationSeconds = newValue }
    }

    public var islandMultiActivityEnabled: Bool {
        get { draftSnapshot.multiActivityEnabled }
        set { mutateDraft { $0.multiActivityEnabled = newValue } }
    }

    public var islandMaxCompactActivityIcons: Int {
        get { draftSnapshot.maxCompactActivityIcons }
        set { mutateDraft { $0.maxCompactActivityIcons = newValue } }
    }

    public var islandEventSystemMetricsEnabled: Bool {
        get { draftSnapshot.eventSystemMetricsEnabled }
        set { mutateDraft { $0.eventSystemMetricsEnabled = newValue } }
    }

    public var islandEventMicrophoneEnabled: Bool {
        get { draftSnapshot.eventMicrophoneEnabled }
        set { mutateDraft { $0.eventMicrophoneEnabled = newValue } }
    }

    public var islandEventCameraEnabled: Bool {
        get { draftSnapshot.eventCameraEnabled }
        set { mutateDraft { $0.eventCameraEnabled = newValue } }
    }

    public var islandEventAudioDeviceEnabled: Bool {
        get { draftSnapshot.eventAudioDeviceEnabled }
        set { mutateDraft { $0.eventAudioDeviceEnabled = newValue } }
    }

    public var islandEventMediaEnabled: Bool {
        get { draftSnapshot.eventMediaEnabled }
        set { mutateDraft { $0.eventMediaEnabled = newValue } }
    }

    public var islandMediaExpandOnTrackChange: Bool {
        get { draftSnapshot.mediaExpandOnTrackChange }
        set { mutateDraft { $0.mediaExpandOnTrackChange = newValue } }
    }

    public var islandEventNotificationsEnabled: Bool {
        get { draftSnapshot.eventNotificationsEnabled }
        set { mutateDraft { $0.eventNotificationsEnabled = newValue } }
    }

    public var islandWidgetShowsCPU: Bool {
        get { draftSnapshot.widgetShowsCPU }
        set { mutateDraft { $0.widgetShowsCPU = newValue } }
    }

    public var islandWidgetShowsRAM: Bool {
        get { draftSnapshot.widgetShowsRAM }
        set { mutateDraft { $0.widgetShowsRAM = newValue } }
    }

    public var islandWidgetShowsDisk: Bool {
        get { draftSnapshot.widgetShowsDisk }
        set { mutateDraft { $0.widgetShowsDisk = newValue } }
    }

    public var islandWidgetShowsBattery: Bool {
        get { draftSnapshot.widgetShowsBattery }
        set { mutateDraft { $0.widgetShowsBattery = newValue } }
    }

    public var islandWidgetShowsTime: Bool {
        get { draftSnapshot.widgetShowsTime }
        set { mutateDraft { $0.widgetShowsTime = newValue } }
    }

    public var islandWidgetShowsDate: Bool {
        get { draftSnapshot.widgetShowsDate }
        set { mutateDraft { $0.widgetShowsDate = newValue } }
    }

    public var islandWidgetShowsNetwork: Bool {
        get { draftSnapshot.widgetShowsNetwork }
        set { mutateDraft { $0.widgetShowsNetwork = newValue } }
    }

    public var islandWidgetShowsTemperature: Bool {
        get { draftSnapshot.widgetShowsTemperature }
        set { mutateDraft { $0.widgetShowsTemperature = newValue } }
    }

    public var islandWidgetShowsMusic: Bool {
        get { draftSnapshot.widgetShowsMusic }
        set { mutateDraft { $0.widgetShowsMusic = newValue } }
    }

    public var islandWidgetOrder: [String] {
        get { draftSnapshot.widgetOrder }
        set { mutateDraft { $0.widgetOrder = newValue } }
    }

  /// Values used by the floating island and event providers.
    public var runtimeSnapshot: DynamicIslandSettingsSnapshot { appliedSnapshot }

    public func applyPendingChanges() {
        commitDraftToApplied()
    }

    public func revertPendingChanges() {
        draftSnapshot = appliedSnapshot
        pendingChanges = false
    }

    public func resetAppearanceToDefaults() {
        mutateDraft { $0.resetAppearanceToDefaults() }
    }

    private func mutateDraft(_ body: (inout DynamicIslandSettingsSnapshot) -> Void) {
        var next = draftSnapshot
        body(&next)
        draftSnapshot = next
    }

    private func commitDraftToApplied() {
        appliedSnapshot = draftSnapshot
        Self.persistSnapshot(draftSnapshot, to: defaults)
        pendingChanges = false
        NotificationCenter.default.post(name: Notifications.appliedDidChange, object: self)
    }

    private static func loadSnapshot(from defaults: UserDefaults) -> DynamicIslandSettingsSnapshot {
        var snap = DynamicIslandSettingsSnapshot.defaults
        snap.dynamicIslandEnabled = defaults.object(forKey: Keys.islandEnabled) as? Bool ?? snap.dynamicIslandEnabled
        let islandMode = defaults.string(forKey: Keys.islandDisplayMode) ?? snap.displayMode.rawValue
        snap.displayMode = IslandDisplayMode(rawValue: islandMode) ?? .builtIn
        if let storedID = defaults.object(forKey: Keys.islandDisplayID) as? Int {
            snap.displayID = CGDirectDisplayID(storedID)
        }
        snap.verticalOffset = CGFloat(defaults.object(forKey: Keys.islandVerticalOffset) as? Double ?? Double(snap.verticalOffset))
        snap.compactHeight = CGFloat(defaults.object(forKey: Keys.islandCompactHeight) as? Double ?? Double(snap.compactHeight))
        snap.expandedHeight = CGFloat(defaults.object(forKey: Keys.islandExpandedHeight) as? Double ?? Double(snap.expandedHeight))
        snap.expandedWidth = CGFloat(defaults.object(forKey: Keys.islandExpandedWidth) as? Double ?? Double(snap.expandedWidth))
        snap.backgroundOpacity = defaults.object(forKey: Keys.islandBackgroundOpacity) as? Double ?? snap.backgroundOpacity
        if defaults.object(forKey: Keys.islandLiquidGlass) == nil {
            snap.liquidGlassEnabled = true
        } else {
            snap.liquidGlassEnabled = defaults.bool(forKey: Keys.islandLiquidGlass)
        }
        snap.liquidGlassTintOpacity = defaults.object(forKey: Keys.islandLiquidGlassTint) as? Double ?? snap.liquidGlassTintOpacity
        snap.cornerRadius = CGFloat(defaults.object(forKey: Keys.islandCornerRadius) as? Double ?? Double(snap.cornerRadius))
        snap.chromeRed = defaults.object(forKey: Keys.islandChromeRed) as? Double ?? snap.chromeRed
        snap.chromeGreen = defaults.object(forKey: Keys.islandChromeGreen) as? Double ?? snap.chromeGreen
        snap.chromeBlue = defaults.object(forKey: Keys.islandChromeBlue) as? Double ?? snap.chromeBlue
        snap.accentRed = defaults.object(forKey: Keys.islandAccentRed) as? Double ?? snap.accentRed
        snap.accentGreen = defaults.object(forKey: Keys.islandAccentGreen) as? Double ?? snap.accentGreen
        snap.accentBlue = defaults.object(forKey: Keys.islandAccentBlue) as? Double ?? snap.accentBlue
        snap.foregroundRed = defaults.object(forKey: Keys.islandForegroundRed) as? Double ?? snap.foregroundRed
        snap.foregroundGreen = defaults.object(forKey: Keys.islandForegroundGreen) as? Double ?? snap.foregroundGreen
        snap.foregroundBlue = defaults.object(forKey: Keys.islandForegroundBlue) as? Double ?? snap.foregroundBlue
        snap.compactWidth = CGFloat(defaults.object(forKey: Keys.islandCompactWidth) as? Double ?? Double(snap.compactWidth))
        snap.animationDuration = defaults.object(forKey: Keys.islandAnimationDuration) as? TimeInterval ?? snap.animationDuration
        snap.autoCollapseSeconds = defaults.object(forKey: Keys.islandAutoCollapse) as? TimeInterval ?? snap.autoCollapseSeconds
        snap.hoverExpands = defaults.object(forKey: Keys.islandHoverExpands) as? Bool ?? snap.hoverExpands
        snap.clickExpands = defaults.object(forKey: Keys.islandClickExpands) as? Bool ?? snap.clickExpands
        snap.hoverDelaySeconds = defaults.object(forKey: Keys.islandHoverDelay) as? TimeInterval ?? snap.hoverDelaySeconds
        snap.notificationDurationSeconds = defaults.object(forKey: Keys.islandNotificationDuration) as? TimeInterval ?? snap.notificationDurationSeconds
        snap.multiActivityEnabled = defaults.object(forKey: Keys.islandMultiActivity) as? Bool ?? snap.multiActivityEnabled
        snap.maxCompactActivityIcons = defaults.object(forKey: Keys.islandMaxCompactIcons) as? Int ?? snap.maxCompactActivityIcons

        snap.eventSystemMetricsEnabled = eventFlag("systemMetrics", default: snap.eventSystemMetricsEnabled, defaults: defaults)
        snap.eventMicrophoneEnabled = eventFlag("microphone", default: snap.eventMicrophoneEnabled, defaults: defaults)
        snap.eventCameraEnabled = eventFlag("camera", default: snap.eventCameraEnabled, defaults: defaults)
        snap.eventAudioDeviceEnabled = eventFlag("audioDevice", default: snap.eventAudioDeviceEnabled, defaults: defaults)
        snap.eventMediaEnabled = eventFlag("media", default: snap.eventMediaEnabled, defaults: defaults)
        snap.mediaExpandOnTrackChange = defaults.object(forKey: Keys.islandMediaExpandOnTrackChange) as? Bool ?? snap.mediaExpandOnTrackChange
        snap.eventNotificationsEnabled = eventFlag("notifications", default: snap.eventNotificationsEnabled, defaults: defaults)

        snap.widgetShowsCPU = widgetFlag("cpu", default: snap.widgetShowsCPU, defaults: defaults)
        snap.widgetShowsRAM = widgetFlag("ram", default: snap.widgetShowsRAM, defaults: defaults)
        snap.widgetShowsDisk = widgetFlag("disk", default: snap.widgetShowsDisk, defaults: defaults)
        snap.widgetShowsBattery = widgetFlag("battery", default: snap.widgetShowsBattery, defaults: defaults)
        snap.widgetShowsTime = widgetFlag("time", default: snap.widgetShowsTime, defaults: defaults)
        snap.widgetShowsDate = widgetFlag("date", default: snap.widgetShowsDate, defaults: defaults)
        snap.widgetShowsNetwork = widgetFlag("network", default: snap.widgetShowsNetwork, defaults: defaults)
        snap.widgetShowsTemperature = widgetFlag("temp", default: snap.widgetShowsTemperature, defaults: defaults)
        snap.widgetShowsMusic = widgetFlag("music", default: snap.widgetShowsMusic, defaults: defaults)

        if let stored = defaults.string(forKey: Keys.islandWidgetOrder) {
            snap.widgetOrder = stored.split(separator: ",").map(String.init)
        }
        return snap
    }

    private static func persistSnapshot(_ snap: DynamicIslandSettingsSnapshot, to defaults: UserDefaults) {
        defaults.set(snap.dynamicIslandEnabled, forKey: Keys.islandEnabled)
        defaults.set(snap.displayMode.rawValue, forKey: Keys.islandDisplayMode)
        if let id = snap.displayID {
            defaults.set(Int(id), forKey: Keys.islandDisplayID)
        } else {
            defaults.removeObject(forKey: Keys.islandDisplayID)
        }
        defaults.set(Double(snap.verticalOffset), forKey: Keys.islandVerticalOffset)
        defaults.set(Double(snap.compactHeight), forKey: Keys.islandCompactHeight)
        defaults.set(Double(snap.expandedHeight), forKey: Keys.islandExpandedHeight)
        defaults.set(Double(snap.expandedWidth), forKey: Keys.islandExpandedWidth)
        defaults.set(snap.backgroundOpacity, forKey: Keys.islandBackgroundOpacity)
        defaults.set(snap.liquidGlassEnabled, forKey: Keys.islandLiquidGlass)
        defaults.set(snap.liquidGlassTintOpacity, forKey: Keys.islandLiquidGlassTint)
        defaults.set(Double(snap.cornerRadius), forKey: Keys.islandCornerRadius)
        defaults.set(snap.chromeRed, forKey: Keys.islandChromeRed)
        defaults.set(snap.chromeGreen, forKey: Keys.islandChromeGreen)
        defaults.set(snap.chromeBlue, forKey: Keys.islandChromeBlue)
        defaults.set(snap.accentRed, forKey: Keys.islandAccentRed)
        defaults.set(snap.accentGreen, forKey: Keys.islandAccentGreen)
        defaults.set(snap.accentBlue, forKey: Keys.islandAccentBlue)
        defaults.set(snap.foregroundRed, forKey: Keys.islandForegroundRed)
        defaults.set(snap.foregroundGreen, forKey: Keys.islandForegroundGreen)
        defaults.set(snap.foregroundBlue, forKey: Keys.islandForegroundBlue)
        defaults.set(Double(snap.compactWidth), forKey: Keys.islandCompactWidth)
        defaults.set(snap.animationDuration, forKey: Keys.islandAnimationDuration)
        defaults.set(snap.autoCollapseSeconds, forKey: Keys.islandAutoCollapse)
        defaults.set(snap.hoverExpands, forKey: Keys.islandHoverExpands)
        defaults.set(snap.clickExpands, forKey: Keys.islandClickExpands)
        defaults.set(snap.hoverDelaySeconds, forKey: Keys.islandHoverDelay)
        defaults.set(snap.notificationDurationSeconds, forKey: Keys.islandNotificationDuration)
        defaults.set(snap.multiActivityEnabled, forKey: Keys.islandMultiActivity)
        defaults.set(snap.maxCompactActivityIcons, forKey: Keys.islandMaxCompactIcons)

        setEventFlag("systemMetrics", snap.eventSystemMetricsEnabled, defaults: defaults)
        setEventFlag("microphone", snap.eventMicrophoneEnabled, defaults: defaults)
        setEventFlag("camera", snap.eventCameraEnabled, defaults: defaults)
        setEventFlag("audioDevice", snap.eventAudioDeviceEnabled, defaults: defaults)
        setEventFlag("media", snap.eventMediaEnabled, defaults: defaults)
        defaults.set(snap.mediaExpandOnTrackChange, forKey: Keys.islandMediaExpandOnTrackChange)
        setEventFlag("notifications", snap.eventNotificationsEnabled, defaults: defaults)

        setWidgetFlag("cpu", snap.widgetShowsCPU, defaults: defaults)
        setWidgetFlag("ram", snap.widgetShowsRAM, defaults: defaults)
        setWidgetFlag("disk", snap.widgetShowsDisk, defaults: defaults)
        setWidgetFlag("battery", snap.widgetShowsBattery, defaults: defaults)
        setWidgetFlag("time", snap.widgetShowsTime, defaults: defaults)
        setWidgetFlag("date", snap.widgetShowsDate, defaults: defaults)
        setWidgetFlag("network", snap.widgetShowsNetwork, defaults: defaults)
        setWidgetFlag("temp", snap.widgetShowsTemperature, defaults: defaults)
        setWidgetFlag("music", snap.widgetShowsMusic, defaults: defaults)
        defaults.set(snap.widgetOrder.joined(separator: ","), forKey: Keys.islandWidgetOrder)
    }

    private static func widgetFlag(_ name: String, default defaultValue: Bool, defaults: UserDefaults) -> Bool {
        let key = Keys.islandWidgetPrefix + name
        if defaults.object(forKey: key) == nil { return defaultValue }
        return defaults.bool(forKey: key)
    }

    private static func setWidgetFlag(_ name: String, _ value: Bool, defaults: UserDefaults) {
        defaults.set(value, forKey: Keys.islandWidgetPrefix + name)
    }

    private static func eventFlag(_ name: String, default defaultValue: Bool, defaults: UserDefaults) -> Bool {
        let key = Keys.islandEventPrefix + name
        if defaults.object(forKey: key) == nil { return defaultValue }
        return defaults.bool(forKey: key)
    }

    private static func setEventFlag(_ name: String, _ value: Bool, defaults: UserDefaults) {
        defaults.set(value, forKey: Keys.islandEventPrefix + name)
    }
}
