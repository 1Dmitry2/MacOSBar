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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let metrics: IslandLayoutMetrics
    public let mode: IslandPresentationMode
    public let interactive: Bool
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
        loadLiveData: Bool = true,
        animatesSizeChanges: Bool = true,
        onTap: (() -> Void)? = nil,
        onHoverChanged: ((Bool) -> Void)? = nil
    ) {
        self.metrics = metrics
        self.mode = mode
        self._clock = ObservedObject(wrappedValue: clock)
        self.interactive = interactive
        self.loadLiveData = loadLiveData
        self.animatesSizeChanges = animatesSizeChanges
        self.onTap = onTap
        self.onHoverChanged = onHoverChanged
    }

  private var targetSize: CGSize { metrics.size(for: mode) }

    private var islandSettings: DynamicIslandSettingsSnapshot {
        interactive ? islandConfig.runtimeSnapshot : islandConfig.draftSnapshot
    }

    private var cornerRadius: CGFloat {
        let base = islandSettings.cornerRadius
        // Bottom corners only on notched Macs; keep radius stable so expansion does not “pop” new corners at the lip.
        return metrics.integratesNotch ? base : (mode.isExpandedLayout && !mode.isHoverPeek ? base + 4 : base)
    }

    private var chromeOpacity: Double {
        min(1, max(islandSettings.backgroundOpacity, 0.94))
    }

    private var usesCapsuleChrome: Bool {
        metrics.integratesNotch && (mode == .idle || mode.isHoverPeek)
    }

    private var expandedBelowNotchLip: Bool {
        metrics.integratesNotch
            && (mode.isExpandedLayout && !mode.isHoverPeek || targetSize.height > metrics.notchBandHeight + 0.5)
    }

    private var clipShape: IslandClipShape {
        IslandClipShape(
            integratesNotchLip: metrics.integratesNotch,
            notchLipWidth: metrics.compactSize.width,
            notchBandHeight: metrics.notchBandHeight,
            expandedBelowLip: expandedBelowNotchLip,
            capsule: usesCapsuleChrome && !metrics.integratesNotch,
            cornerRadius: cornerRadius
        )
    }

    public var body: some View {
        ZStack(alignment: .top) {
            IslandChrome(
                size: targetSize,
                cornerRadius: cornerRadius,
                opacity: chromeOpacity,
                integratesNotch: metrics.integratesNotch,
                notchLipWidth: metrics.compactSize.width,
                notchBandHeight: metrics.notchBandHeight,
                expandedBelowLip: expandedBelowNotchLip
            )
            laidOutContent
                .opacity(contentOpacity)
        }
        .frame(width: targetSize.width, height: targetSize.height)
        .clipShape(clipShape)
        .contentShape(clipShape)
        .animation(islandContentAnimation, value: mode)
        .animation(animatesSizeChanges ? islandContentAnimation : nil, value: targetSize)
        .onTapGesture {
            guard interactive else { return }
            onTap?()
        }
        .onHover { inside in
            guard interactive else { return }
            onHoverChanged?(inside)
        }
        .onAppear {
            guard loadLiveData else { return }
            monitor.start()
            nowPlaying.refresh()
        }
    }

    private var islandContentAnimation: Animation? {
        reduceMotion ? nil : IslandAnimationPolicy.swiftUIAnimation
    }

    private var contentOpacity: Double {
        switch mode {
        case .idle, .hover, .expanded, .music, .notification, .multiple,
             .mic, .camera, .headphones:
            return 1
        }
    }

    @ViewBuilder
    private var laidOutContent: some View {
        if metrics.integratesNotch {
            VStack(spacing: 0) {
                if mode.isExpandedLayout && !mode.isHoverPeek {
                    Color.clear
                        .frame(height: metrics.notchBandHeight)
                        .allowsHitTesting(false)
                    content
                        .frame(
                            maxWidth: .infinity,
                            minHeight: metrics.expandedBodyHeight,
                            maxHeight: metrics.expandedBodyHeight,
                            alignment: .top
                        )
                } else {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        content
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, metrics.compactContentBottomInset)
                }
            }
            .frame(width: targetSize.width, height: targetSize.height, alignment: .top)
        } else {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private var compactHasVisibleWidgets: Bool {
        !orderedCompactWidgets().isEmpty
    }

    private var compactHasActivityGlyphs: Bool {
        if islandSettings.multiActivityEnabled, !activityState.compactActivityIcons.isEmpty { return true }
        return systemEvents.snapshot.microphoneActive || systemEvents.snapshot.cameraActive
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .idle, .hover:
            compactContent
        case .expanded:
            expandedContent
        case .notification:
            notificationContent
        case .mic:
            deviceActivityContent(icon: "mic.fill", titleKey: "island.preview.mode.mic")
        case .camera:
            deviceActivityContent(icon: "video.fill", titleKey: "island.preview.mode.camera")
        case .headphones:
            deviceActivityContent(icon: "headphones", titleKey: "island.preview.mode.headphones")
        case .music:
            musicExpandedContent
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

    private var compactContent: some View {
        Group {
            if compactHasVisibleWidgets || compactHasActivityGlyphs {
                HStack(spacing: 8) {
                    compactActivityIndicators
                    ForEach(orderedCompactWidgets(), id: \.self) { widget in
                        compactWidget(widget)
                    }
                }
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal, 10)
                .lineLimit(1)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
            } else {
                Color.clear
                    .frame(height: 1)
                    .accessibilityLabel("Dynamic Island")
            }
        }
    }

    @ViewBuilder
    private var compactActivityIndicators: some View {
        if islandSettings.multiActivityEnabled, !activityState.compactActivityIcons.isEmpty {
            ForEach(activityState.compactActivityIcons) { activity in
                Image(systemName: activity.systemImage)
                    .font(.caption.weight(.semibold))
                    .symbolEffect(.pulse, options: .repeating, isActive: activity.kind == .microphone)
            }
        } else {
            if systemEvents.snapshot.microphoneActive {
                Image(systemName: "mic.fill")
                    .font(.caption.weight(.semibold))
                    .symbolEffect(.pulse, options: .repeating)
            }
            if systemEvents.snapshot.cameraActive {
                Image(systemName: "video.fill")
                    .font(.caption.weight(.semibold))
            }
        }
    }

    private func orderedCompactWidgets() -> [IslandWidgetID] {
        guard islandSettings.eventSystemMetricsEnabled else {
            return islandSettings.widgetShowsMusic ? [.music] : []
        }
        return islandSettings.enabledIslandWidgets().filter { id in
            switch id {
            case .time, .cpu, .ram, .music: return true
            default: return false
            }
        }
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
            metricChip(icon: "cpu", value: String(format: "%.0f%%", monitor.dashboard.cpu.totalUsage))
                .matchedGeometryEffect(id: "cpu", in: islandNamespace)
        case .ram where islandSettings.widgetShowsRAM:
            metricChip(icon: "memorychip", value: String(format: "%.0f%%", monitor.dashboard.memory.usedFraction * 100))
        case .music:
            if islandSettings.widgetShowsMusic, let title = nowPlaying.title {
                musicChip(title: title, playing: nowPlaying.isPlaying)
            }
        default:
            EmptyView()
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow
            optionalMusicRow
            statsGrid
        }
        .foregroundStyle(.white.opacity(0.94))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
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

    private var activityContent: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
                .foregroundStyle(HubTheme.successGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.tr("island.preview.activity.title"))
                    .font(.subheadline.weight(.semibold))
                Text(L10n.tr("island.preview.activity.body"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }
            Spacer()
            Text("12:45")
                .font(.caption.monospacedDigit())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.white.opacity(0.12), in: Capsule())
        }
        .foregroundStyle(.white.opacity(0.94))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var musicExpandedContent: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [HubTheme.accentPurple.opacity(0.9), .purple.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "music.note")
                        .foregroundStyle(.white)
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(nowPlaying.title ?? L10n.tr("island.preview.music.title"))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(nowPlaying.artist ?? L10n.tr("island.preview.music.artist"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                .font(.caption)
        }
        .foregroundStyle(.white.opacity(0.94))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
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

    private var systemMonitorContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("island.preview.monitor.title"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            HStack(spacing: 12) {
                if islandSettings.widgetShowsCPU {
                    islandStat(title: "CPU", value: String(format: "%.1f%%", monitor.dashboard.cpu.totalUsage))
                }
                if islandSettings.widgetShowsRAM {
                    islandStat(title: "RAM", value: String(format: "%.1f%%", monitor.dashboard.memory.usedFraction * 100))
                }
                if islandSettings.widgetShowsDisk {
                    islandStat(title: L10n.tr("island.widget.disk"), value: String(format: "%.0f%%", monitor.dashboard.disk.usedPercent))
                }
                if islandSettings.widgetShowsBattery, let level = monitor.dashboard.power.levelPercent {
                    islandStat(title: L10n.tr("island.widget.battery.short"), value: String(format: "%.0f%%", level))
                }
            }
        }
        .foregroundStyle(.white.opacity(0.94))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if islandSettings.widgetShowsTime {
                Text(clock.timeString)
                    .font(.headline)
                    .monospacedDigit()
                    .matchedGeometryEffect(id: "time", in: islandNamespace)
            }
            if islandSettings.widgetShowsDate {
                Text(clock.dateString)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 4)
            if islandSettings.widgetShowsNetwork {
                metricChip(icon: "arrow.down.circle", value: rate(monitor.dashboard.network.bytesInPerSec))
                metricChip(icon: "arrow.up.circle", value: rate(monitor.dashboard.network.bytesOutPerSec))
            }
        }
    }

    @ViewBuilder
    private var optionalMusicRow: some View {
        if islandSettings.widgetShowsMusic, let title = nowPlaying.title {
            HStack(spacing: 6) {
                Image(systemName: nowPlaying.isPlaying ? "play.fill" : "pause.fill")
                    .font(.caption2)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.subheadline).lineLimit(1)
                    if let artist = nowPlaying.artist {
                        Text(artist).font(.caption2).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
                    }
                }
            }
        }
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            if islandSettings.widgetShowsCPU {
                islandStat(title: "CPU", value: String(format: "%.1f%%", monitor.dashboard.cpu.totalUsage))
            }
            if islandSettings.widgetShowsRAM {
                islandStat(title: "RAM", value: String(format: "%.1f%%", monitor.dashboard.memory.usedFraction * 100))
            }
            if islandSettings.widgetShowsDisk {
                islandStat(title: L10n.tr("island.widget.disk"), value: String(format: "%.0f%%", monitor.dashboard.disk.usedPercent))
            }
            if islandSettings.widgetShowsTemperature, let temp = monitor.dashboard.temperature.cpuCelsius {
                islandStat(title: L10n.tr("island.widget.temp.short"), value: String(format: "%.0f°", temp))
            } else if islandSettings.widgetShowsTemperature {
                islandStat(title: L10n.tr("island.widget.temp.short"), value: "—")
            }
            if islandSettings.widgetShowsBattery, let level = monitor.dashboard.power.levelPercent {
                islandStat(title: L10n.tr("island.widget.battery.short"), value: String(format: "%.0f%%", level))
            }
        }
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

    private func metricChip(icon: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(value)
        }
        .font(.caption)
    }

    private func islandStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).opacity(0.7)
            Text(value).font(.headline)
        }
    }

    private func rate(_ v: Double) -> String {
        ByteCountFormat.string(Int64(v)) + "/s"
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
