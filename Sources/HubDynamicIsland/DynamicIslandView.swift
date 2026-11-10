import AppKit
import Combine
import HubCore
import HubSettings
import HubSystemMonitor
import SwiftUI

public struct DynamicIslandView: View {
    @ObservedObject private var clock: IslandClock
    @Bindable private var monitor = SystemMetricsService.shared
    @Bindable private var nowPlaying = NowPlayingMonitor.shared
    @Bindable private var islandConfig = DynamicIslandConfiguration.shared
    @Bindable private var systemEvents = IslandSystemEventViewModel.shared
    @Bindable private var activityState = DynamicIslandStateManager.shared
    @Bindable private var nookStore = IslandNookStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let metrics: IslandLayoutMetrics
    private let mode: IslandPresentationMode
    @ObservedObject private var interaction = IslandStateManager.shared
    public let interactive: Bool
    /// When `interactive` is false (settings preview), nook buttons still work if this is true.
    public let nookControlsEnabled: Bool
    public let loadLiveData: Bool
    public let animatesSizeChanges: Bool
    public var onTap: (() -> Void)?
    public var onHoverChanged: ((Bool) -> Void)?

    @Namespace private var islandNamespace

    public init(
        metrics: IslandLayoutMetrics,
        mode: IslandPresentationMode,
        clock: IslandClock = IslandClock(),
        interactive: Bool = true,
        nookControlsEnabled: Bool? = nil,
        loadLiveData: Bool = true,
        animatesSizeChanges: Bool = true,
        onTap: (() -> Void)? = nil,
        onHoverChanged: ((Bool) -> Void)? = nil
    ) {
        self.metrics = metrics
        self.mode = mode
        self._clock = ObservedObject(wrappedValue: clock)
        self.interactive = interactive
        self.nookControlsEnabled = nookControlsEnabled ?? interactive
        self.loadLiveData = loadLiveData
        self.animatesSizeChanges = animatesSizeChanges
        self.onTap = onTap
        self.onHoverChanged = onHoverChanged
    }

    private var effectiveMode: IslandPresentationMode {
        interactive ? interaction.presentationMode : mode
    }

    private var targetSize: CGSize { metrics.size(for: effectiveMode) }

    private var cardSize: CGSize { metrics.panelCardSize(for: effectiveMode) }

    private var contentHostSize: CGSize { cardSize }

    private var islandSettings: DynamicIslandSettingsSnapshot {
        interactive ? islandConfig.runtimeSnapshot : islandConfig.draftSnapshot
    }

    private var cornerRadius: CGFloat {
        let base = islandSettings.cornerRadius
        // Bottom corners only on notched Macs; keep radius stable so expansion does not “pop” new corners at the lip.
        return metrics.integratesNotch ? base : (effectiveMode.isExpandedLayout ? base + 4 : base)
    }

    private var chromeOpacity: Double {
        min(1, max(islandSettings.backgroundOpacity, 0.12))
    }

    private var chromeColors: IslandChromeColors {
        IslandChromeColors.from(snapshot: islandSettings)
    }

    private var usesCapsuleChrome: Bool {
        metrics.integratesNotch && effectiveMode == .idle
    }

    private var chromeIntegratesNotch: Bool {
        metrics.integratesNotch && effectiveMode != .idle
    }

    private var clipShape: IslandClipShape {
        let floatingCompact = metrics.integratesNotch && effectiveMode == .idle
        return IslandClipShape(
            integratesNotchLip: chromeIntegratesNotch,
            capsule: effectiveMode == .idle,
            cornerRadius: floatingCompact ? min(cornerRadius, 20) : cornerRadius
        )
    }

    public var body: some View {
        Group {
            if effectiveMode.usesNookDock {
                nookLayout
            } else {
                compactIslandLayout
            }
        }
        .animation(islandContentAnimation, value: effectiveMode)
        .animation(animatesSizeChanges ? islandContentAnimation : nil, value: targetSize)
        .animation(islandContentAnimation, value: nookStore.selectedSection)
        .animation(islandContentAnimation, value: nookStore.focusRunning)
        .animation(islandContentAnimation, value: nookStore.focusRemainingSeconds)
        .onHover { inside in
            guard !interactive else { return }
            onHoverChanged?(inside)
        }
        .onAppear {
            guard loadLiveData else { return }
            monitor.start()
            nowPlaying.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: DynamicIslandConfiguration.Notifications.appliedDidChange)) { _ in
            guard interactive, loadLiveData else { return }
            nowPlaying.refresh()
        }
    }

    private var compactFloatingPillSize: CGSize { metrics.compactFloatingPillSize }

    private var compactIslandLayout: some View {
        Group {
            if metrics.integratesNotch, effectiveMode == .idle {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: metrics.compactFloatingPillTopInset)
                        .allowsHitTesting(false)
                    islandCard(
                        chromeSize: compactFloatingPillSize,
                        content: compactFloatingContent,
                        allowTapToToggle: true
                    )
                    .frame(width: compactFloatingPillSize.width, height: compactFloatingPillSize.height)
                }
                .frame(width: targetSize.width, height: targetSize.height, alignment: .top)
            } else {
                islandCard(chromeSize: targetSize, content: laidOutContent, allowTapToToggle: true)
                    .frame(width: targetSize.width, height: targetSize.height)
            }
        }
    }

    private var compactFloatingContent: some View {
        compactContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 2)
    }

    private var nookLayout: some View {
        VStack(spacing: IslandLayoutMetrics.nookDockSpacing) {
            islandCard(chromeSize: cardSize, content: laidOutContent, allowTapToToggle: false)
                .frame(width: cardSize.width, height: cardSize.height)
            IslandNookDockView(
                store: nookStore,
                settings: islandSettings,
                chrome: chromeColors,
                accent: chromeColors.accent,
                actionsEnabled: nookControlsEnabled
            )
            .frame(width: cardSize.width, height: IslandLayoutMetrics.nookDockHeight)
        }
        .frame(width: targetSize.width, height: targetSize.height, alignment: .top)
    }

    private func islandCard(chromeSize: CGSize, content: some View, allowTapToToggle: Bool = true) -> some View {
        ZStack(alignment: .top) {
            IslandChrome(
                size: chromeSize,
                cornerRadius: cornerRadius,
                opacity: chromeOpacity,
                integratesNotch: chromeIntegratesNotch,
                background: chromeColors.background,
                liquidGlass: islandSettings.liquidGlassEnabled,
                glassTintOpacity: islandSettings.liquidGlassTintOpacity
            )
            content
                .opacity(contentOpacity)
                .zIndex(1)
        }
        .clipShape(clipShape)
        .contentShape(clipShape)
        .modifier(IslandExpandTapModifier(enabled: interactive && allowTapToToggle, onTap: onTap))
    }

    private var islandContentAnimation: Animation? {
        reduceMotion ? nil : IslandAnimationPolicy.swiftUIAnimation
    }

    private var contentOpacity: Double {
        switch effectiveMode {
        case .idle, .hover, .expanded, .music, .notification, .multiple,
             .mic, .camera, .headphones:
            return 1
        }
    }

    @ViewBuilder
    private var laidOutContent: some View {
        if metrics.integratesNotch {
            VStack(spacing: 0) {
                if effectiveMode.isExpandedLayout {
                    Color.clear
                        .frame(height: metrics.occlusionReserveHeight)
                        .allowsHitTesting(false)
                    content
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .top
                        )
                        .padding(.bottom, effectiveMode.usesNookDock ? 4 : 0)
                } else {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: metrics.occlusionReserveHeight)
                            .allowsHitTesting(false)
                        content
                            .frame(
                                maxWidth: .infinity,
                                minHeight: metrics.compactReadableStripHeight,
                                maxHeight: metrics.compactReadableStripHeight,
                                alignment: .center
                            )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.bottom, metrics.compactContentBottomInset)
                }
            }
            .frame(width: contentHostSize.width, height: contentHostSize.height, alignment: .top)
        } else {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private var compactHasVisibleWidgets: Bool {
        !orderedCompactWidgets().isEmpty
    }

    private var compactHasActivityGlyphs: Bool {
        !compactSystemActivityIcons.isEmpty
    }

    @ViewBuilder
    private var content: some View {
        switch effectiveMode {
        case .idle:
            compactContent
        case .hover, .expanded, .music:
            nookPanelContent
        case .notification:
            notificationContent
        case .mic:
            deviceActivityContent(icon: "mic.fill", titleKey: "island.preview.mode.mic")
        case .camera:
            deviceActivityContent(icon: "video.fill", titleKey: "island.preview.mode.camera")
        case .headphones:
            deviceActivityContent(icon: "headphones", titleKey: "island.preview.mode.headphones")
        case .multiple:
            multipleActivitiesContent
        }
    }

    private func deviceActivityContent(icon: String, titleKey: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(HubTheme.accentPurple)
            Text(L10n.tr(titleKey))
                .font(.subheadline.weight(.semibold))
            Spacer(minLength: 0)
            ProgressView()
                .controlSize(.small)
                .tint(.white.opacity(0.85))
        }
        .foregroundStyle(.white.opacity(0.94))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private enum CompactFocus: Equatable {
        case restCapsule
        case media
        case focus
        case focusAndMedia
        case systemActivity(IslandActivity)
        case metrics
    }

    private var compactFocus: CompactFocus {
        let media = islandSettings.eventMediaEnabled && showsNowPlayingInCompact
        let focusActive = nookStore.focusRunning && (nookStore.focusRemainingSeconds ?? -1) >= 0
        if focusActive, media { return .focusAndMedia }
        if focusActive { return .focus }
        if media { return .media }
        if let activity = activityState.dominantCompactActivity(excludingMedia: true) {
            return .systemActivity(activity)
        }
        if compactHasVisibleWidgets, islandSettings.eventSystemMetricsEnabled {
            return .metrics
        }
        return .restCapsule
    }

    private var focusAccent: Color {
        Color.orange
    }

    private var focusSessionTotal: Int {
        let stored = nookStore.focusSessionTotalSeconds
        return stored > 0 ? stored : max(60, nookStore.focusDurationMinutes * 60)
    }

    private var showsNowPlayingInCompact: Bool {
        if nowPlaying.isPlaying { return true }
        if let title = nowPlaying.title, !title.isEmpty { return true }
        return activityState.persistentActivities.contains { $0.kind == .media }
    }

    private var compactContent: some View {
        Group {
            switch compactFocus {
            case .restCapsule:
                compactRestCapsule
            case .media:
                compactMediaOnlyBar
                    .foregroundStyle(chromeColors.foreground.opacity(0.92))
            case .focus:
                if let remaining = nookStore.focusRemainingSeconds {
                    IslandFocusCompactCapsule(
                        remainingSeconds: remaining,
                        totalSeconds: focusSessionTotal,
                        accent: focusAccent
                    )
                }
            case .focusAndMedia:
                if let remaining = nookStore.focusRemainingSeconds {
                    HStack(spacing: 6) {
                        IslandFocusCompactCapsule(
                            remainingSeconds: remaining,
                            totalSeconds: focusSessionTotal,
                            accent: focusAccent
                        )
                        albumArtThumb(size: 26)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .padding(.trailing, 6)
                    }
                }
            case .systemActivity(let activity):
                HStack(spacing: 8) {
                    Image(systemName: activity.systemImage)
                        .font(.caption.weight(.semibold))
                    Text(activity.title)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                }
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal, 10)
            case .metrics:
                if compactHasVisibleWidgets {
                    compactWidgetStrip(orderedCompactWidgets())
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.horizontal, 10)
                } else {
                    Color.clear
                        .frame(height: 1)
                        .accessibilityLabel("Dynamic Island")
                }
            }
        }
    }

    @ViewBuilder
    private var compactActivityIndicators: some View {
        let icons = compactSystemActivityIcons
        if !icons.isEmpty {
            ForEach(icons, id: \.self) { symbol in
                Image(systemName: symbol)
                    .font(.caption.weight(.semibold))
                    .symbolEffect(.pulse, options: .repeating, isActive: symbol == "mic.fill")
            }
        }
    }

    private var compactSystemActivityIcons: [String] {
        if islandSettings.multiActivityEnabled, !activityState.compactActivityIcons.isEmpty {
            return activityState.compactActivityIcons.map(\.systemImage)
        }
        var symbols: [String] = []
        if systemEvents.snapshot.microphoneActive { symbols.append("mic.fill") }
        if systemEvents.snapshot.cameraActive { symbols.append("video.fill") }
        if systemEvents.snapshot.activities.contains(where: { $0.kind == .media })
            || (nowPlaying.isPlaying && nowPlaying.title != nil) {
            symbols.append("music.note")
        }
        return symbols
    }

    private func orderedCompactWidgets(stripMusic: Bool = false) -> [IslandWidgetID] {
        var widgets = islandSettings.enabledIslandWidgets()
        if stripMusic || (islandSettings.eventMediaEnabled && showsNowPlayingInCompact) {
            widgets = widgets.filter { $0 != .music }
        }
        if !islandSettings.eventSystemMetricsEnabled {
            widgets = widgets.filter { id in
                switch id {
                case .time, .date, .music, .battery: return true
                default: return false
                }
            }
        }
        return widgets
    }

    private func compactWidgetStrip(_ widgets: [IslandWidgetID]) -> some View {
        HStack(spacing: 6) {
            ForEach(widgets, id: \.self) { widget in
                compactWidget(widget)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.78)
        .font(.system(size: 10, weight: .semibold, design: .rounded))
    }

    private var artworkPalette: IslandArtworkPalette {
        IslandArtworkPalette.from(artwork: nowPlaying.artwork, fallback: chromeColors.accent)
    }

    private var compactRestCapsule: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(chromeColors.foreground.opacity(0.85))
                .padding(.leading, 4)
            Spacer(minLength: 0)
            Image(systemName: "ellipsis")
                .font(.caption.weight(.bold))
                .foregroundStyle(chromeColors.foreground.opacity(0.75))
                .padding(.trailing, 4)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var compactMediaArtSize: CGFloat {
        (metrics.integratesNotch && effectiveMode == .idle) ? 28 : 24
    }

    private var compactMediaOnlyBar: some View {
        HStack(spacing: 12) {
            albumArtThumb(size: compactMediaArtSize)
            Spacer(minLength: 10)
            IslandAlbumWaveform(active: nowPlaying.isPlaying, palette: artworkPalette)
                .frame(minWidth: 28, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func compactWidget(_ id: IslandWidgetID) -> some View {
        switch id {
        case .time where islandSettings.widgetShowsTime:
            Text(clock.timeString)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .matchedGeometryEffect(id: "time", in: islandNamespace)
        case .cpu where islandSettings.widgetShowsCPU:
            compactStat("CPU", value: String(format: "%.0f%%", monitor.dashboard.cpu.totalUsage))
                .matchedGeometryEffect(id: "cpu", in: islandNamespace)
        case .ram where islandSettings.widgetShowsRAM:
            compactStat("RAM", value: String(format: "%.0f%%", monitor.dashboard.memory.usedFraction * 100))
        case .date where islandSettings.widgetShowsDate:
            Text(clock.dateString)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        case .disk where islandSettings.widgetShowsDisk:
            compactStat(L10n.tr("island.widget.disk.short"), value: String(format: "%.0f%%", monitor.dashboard.disk.usedPercent))
        case .battery where islandSettings.widgetShowsBattery:
            if let level = monitor.dashboard.power.levelPercent {
                compactStat(L10n.tr("island.widget.battery.short"), value: String(format: "%.0f%%", level))
            }
        case .network where islandSettings.widgetShowsNetwork:
            compactStat("↓", value: compactRate(monitor.dashboard.network.bytesInPerSec))
        case .temp where islandSettings.widgetShowsTemperature:
            if let temp = monitor.dashboard.temperature.cpuCelsius {
                compactStat(L10n.tr("island.widget.temp.short"), value: String(format: "%.0f°", temp))
            }
        case .music:
            if islandSettings.widgetShowsMusic, let title = nowPlaying.title {
                musicChip(title: title, playing: nowPlaying.isPlaying)
            }
        default:
            EmptyView()
        }
    }

    private func compactRate(_ bytesPerSec: Double) -> String {
        guard bytesPerSec > 0 else { return "0" }
        return ByteCountFormat.string(Int64(bytesPerSec))
    }

    private var nookContentMetrics: IslandContentMetrics {
        let horizontalPad = IslandNookLayout.panelHorizontalPadding * 2
        let verticalPad = IslandNookLayout.panelTopPadding + IslandNookLayout.panelBottomPadding
        let bodyW = max(220, contentHostSize.width - horizontalPad)
        let bodyH = max(120, metrics.expandedBodyHeight - verticalPad - (effectiveMode.usesNookDock ? 6 : 0))
        return IslandContentMetrics(bodyWidth: bodyW, bodyHeight: bodyH)
    }

    private var nookPanelContent: some View {
        IslandNookPanelHost(
            store: nookStore,
            monitor: monitor,
            nowPlaying: nowPlaying,
            clock: clock,
            settings: islandSettings,
            chrome: chromeColors,
            actionsEnabled: nookControlsEnabled,
            contentMetrics: nookContentMetrics
        )
        .padding(.horizontal, IslandNookLayout.panelHorizontalPadding)
        .padding(.top, IslandNookLayout.panelTopPadding)
        .padding(.bottom, IslandNookLayout.panelBottomPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.islandContentMetrics, nookContentMetrics)
    }

    private var notificationContent: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .foregroundStyle(HubTheme.accentPurple)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.tr("island.preview.notification.title"))
                    .font(.subheadline.weight(.semibold))
                Text(L10n.tr("island.preview.notification.body"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white.opacity(0.94))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func albumArtThumb(size: CGFloat) -> some View {
        Group {
            if let artwork = nowPlaying.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [chromeColors.accent.opacity(0.95), chromeColors.accent.opacity(0.45)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: size * 0.38, weight: .semibold))
                            .foregroundStyle(chromeColors.foreground)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
    }

    private var multipleActivitiesContent: some View {
        let activities = activityState.sortedActivities
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(activities) { activity in
                HStack(spacing: 10) {
                    Image(systemName: activity.systemImage)
                        .foregroundStyle(HubTheme.accentPurple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        if let subtitle = activity.subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .foregroundStyle(.white.opacity(0.94))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func musicChip(title: String, playing: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: playing ? "music.note" : "pause.fill")
                .font(.caption2)
            Text(title)
                .font(.caption2)
                .lineLimit(1)
                .frame(maxWidth: 88)
        }
    }

    private func compactStat(_ label: String, value: String) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(chromeColors.foreground.opacity(0.72))
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
    }

}

private struct IslandExpandTapModifier: ViewModifier {
    let enabled: Bool
    let onTap: (() -> Void)?

    func body(content: Content) -> some View {
        if enabled {
            content.highPriorityGesture(TapGesture().onEnded {
                onTap?()
            })
        } else {
            content
        }
    }
}

public enum IslandWidgetID: String, CaseIterable, Identifiable, Sendable {
    case time, date, cpu, ram, disk, battery, network, temp, music

    public var id: String { rawValue }

    public var snapshotFlag: (DynamicIslandSettingsSnapshot) -> Bool {
        switch self {
        case .time: return { $0.widgetShowsTime }
        case .date: return { $0.widgetShowsDate }
        case .cpu: return { $0.widgetShowsCPU }
        case .ram: return { $0.widgetShowsRAM }
        case .disk: return { $0.widgetShowsDisk }
        case .battery: return { $0.widgetShowsBattery }
        case .network: return { $0.widgetShowsNetwork }
        case .temp: return { $0.widgetShowsTemperature }
        case .music: return { $0.widgetShowsMusic }
        }
    }

    public var localizationKey: String {
        switch self {
        case .time: return "island.widget.time"
        case .date: return "island.widget.date"
        case .cpu: return "island.widget.cpu"
        case .ram: return "island.widget.ram"
        case .disk: return "island.widget.disk"
        case .battery: return "island.widget.battery"
        case .network: return "island.widget.network"
        case .temp: return "island.widget.temp"
        case .music: return "island.widget.music"
        }
    }
}

extension DynamicIslandSettingsSnapshot {
    public func enabledIslandWidgets() -> [IslandWidgetID] {
        let order = widgetOrder.compactMap { IslandWidgetID(rawValue: $0) }
        let effective = order.isEmpty
            ? DynamicIslandSettingsSnapshot.defaultWidgetOrder.compactMap { IslandWidgetID(rawValue: $0) }
            : order
        return effective.filter { id in id.snapshotFlag(self) }
    }
}
