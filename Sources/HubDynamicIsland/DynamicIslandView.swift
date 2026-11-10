import HubCore
import HubSettings
import HubSystemMonitor
import SwiftUI

public struct DynamicIslandView: View {
    @ObservedObject private var clock: IslandClock
    @Bindable private var monitor = SystemMetricsService.shared
    @Bindable private var nowPlaying = NowPlayingMonitor.shared
    @Bindable private var config = AppConfiguration.shared
    @Bindable private var systemEvents = IslandSystemEventViewModel.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let metrics: IslandLayoutMetrics
    public let mode: IslandPresentationMode
    public let interactive: Bool
    public let loadLiveData: Bool
    public let animatesSizeChanges: Bool
    public var onTap: (() -> Void)?

    @Namespace private var islandNamespace

    public init(
        metrics: IslandLayoutMetrics,
        mode: IslandPresentationMode,
        clock: IslandClock = IslandClock(),
        interactive: Bool = true,
        loadLiveData: Bool = true,
        animatesSizeChanges: Bool = true,
        onTap: (() -> Void)? = nil
    ) {
        self.metrics = metrics
        self.mode = mode
        self._clock = ObservedObject(wrappedValue: clock)
        self.interactive = interactive
        self.loadLiveData = loadLiveData
        self.animatesSizeChanges = animatesSizeChanges
        self.onTap = onTap
    }

  private var targetSize: CGSize { metrics.size(for: mode) }

    private var cornerRadius: CGFloat {
        let base = config.islandCornerRadius
        return mode.isExpandedLayout && !mode.isHoverPeek ? base + 4 : base
    }

    private var chromeOpacity: Double {
        min(1, max(config.islandBackgroundOpacity, 0.94))
    }

    private var usesCapsuleChrome: Bool {
        metrics.integratesNotch && (mode == .idle || mode.isHoverPeek)
    }

    public var body: some View {
        ZStack {
            IslandChrome(
                size: targetSize,
                cornerRadius: cornerRadius,
                opacity: chromeOpacity,
                integratesNotch: usesCapsuleChrome,
                expanded: mode.isExpandedLayout && !mode.isHoverPeek
            )
            content
                .opacity(contentOpacity)
        }
        .frame(width: targetSize.width, height: targetSize.height)
        .clipShape(IslandClipShape(capsule: usesCapsuleChrome, cornerRadius: cornerRadius))
        .contentShape(IslandClipShape(capsule: usesCapsuleChrome, cornerRadius: cornerRadius))
        .animation(islandContentAnimation, value: mode)
        .animation(animatesSizeChanges ? islandContentAnimation : nil, value: targetSize)
        .onTapGesture {
            guard interactive else { return }
            onTap?()
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
            systemMonitorContent
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
        HStack(spacing: 10) {
            if systemEvents.snapshot.microphoneActive {
                Image(systemName: "mic.fill")
                    .font(.caption.weight(.semibold))
                    .symbolEffect(.pulse, options: .repeating)
            }
            if systemEvents.snapshot.cameraActive {
                Image(systemName: "video.fill")
                    .font(.caption.weight(.semibold))
            }
            ForEach(orderedCompactWidgets(), id: \.self) { widget in
                compactWidget(widget)
            }
        }
        .foregroundStyle(.white.opacity(0.92))
        .padding(.horizontal, 12)
        .lineLimit(1)
    }

    private func orderedCompactWidgets() -> [IslandWidgetID] {
        guard config.islandEventSystemMetricsEnabled else {
            return config.islandWidgetShowsMusic ? [.music] : []
        }
        return config.enabledIslandWidgets.filter { id in
            switch id {
            case .time, .cpu, .ram, .music: return true
            default: return false
            }
        }
    }

    @ViewBuilder
    private func compactWidget(_ id: IslandWidgetID) -> some View {
        switch id {
        case .time where config.islandWidgetShowsTime:
            Text(clock.timeString)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .matchedGeometryEffect(id: "time", in: islandNamespace)
        case .cpu where config.islandWidgetShowsCPU:
            metricChip(icon: "cpu", value: String(format: "%.0f%%", monitor.dashboard.cpu.totalUsage))
                .matchedGeometryEffect(id: "cpu", in: islandNamespace)
        case .ram where config.islandWidgetShowsRAM:
            metricChip(icon: "memorychip", value: String(format: "%.0f%%", monitor.dashboard.memory.usedFraction * 100))
        case .music:
            if config.islandWidgetShowsMusic, let title = nowPlaying.title {
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

    private var systemMonitorContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("island.preview.monitor.title"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            HStack(spacing: 12) {
                if config.islandWidgetShowsCPU {
                    islandStat(title: "CPU", value: String(format: "%.1f%%", monitor.dashboard.cpu.totalUsage))
                }
                if config.islandWidgetShowsRAM {
                    islandStat(title: "RAM", value: String(format: "%.1f%%", monitor.dashboard.memory.usedFraction * 100))
                }
                if config.islandWidgetShowsDisk {
                    islandStat(title: L10n.tr("island.widget.disk"), value: String(format: "%.0f%%", monitor.dashboard.disk.usedPercent))
                }
                if config.islandWidgetShowsBattery, let level = monitor.dashboard.power.levelPercent {
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
            if config.islandWidgetShowsTime {
                Text(clock.timeString)
                    .font(.headline)
                    .monospacedDigit()
                    .matchedGeometryEffect(id: "time", in: islandNamespace)
            }
            if config.islandWidgetShowsDate {
                Text(clock.dateString)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 4)
            if config.islandWidgetShowsNetwork {
                metricChip(icon: "arrow.down.circle", value: rate(monitor.dashboard.network.bytesInPerSec))
                metricChip(icon: "arrow.up.circle", value: rate(monitor.dashboard.network.bytesOutPerSec))
            }
        }
    }

    @ViewBuilder
    private var optionalMusicRow: some View {
        if config.islandWidgetShowsMusic, let title = nowPlaying.title {
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
            if config.islandWidgetShowsCPU {
                islandStat(title: "CPU", value: String(format: "%.1f%%", monitor.dashboard.cpu.totalUsage))
            }
            if config.islandWidgetShowsRAM {
                islandStat(title: "RAM", value: String(format: "%.1f%%", monitor.dashboard.memory.usedFraction * 100))
            }
            if config.islandWidgetShowsDisk {
                islandStat(title: L10n.tr("island.widget.disk"), value: String(format: "%.0f%%", monitor.dashboard.disk.usedPercent))
            }
            if config.islandWidgetShowsTemperature, let temp = monitor.dashboard.temperature.cpuCelsius {
                islandStat(title: L10n.tr("island.widget.temp.short"), value: String(format: "%.0f°", temp))
            } else if config.islandWidgetShowsTemperature {
                islandStat(title: L10n.tr("island.widget.temp.short"), value: "—")
            }
            if config.islandWidgetShowsBattery, let level = monitor.dashboard.power.levelPercent {
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

    public var configFlag: (AppConfiguration) -> Bool {
        switch self {
        case .time: return { $0.islandWidgetShowsTime }
        case .date: return { $0.islandWidgetShowsDate }
        case .cpu: return { $0.islandWidgetShowsCPU }
        case .ram: return { $0.islandWidgetShowsRAM }
        case .disk: return { $0.islandWidgetShowsDisk }
        case .battery: return { $0.islandWidgetShowsBattery }
        case .network: return { $0.islandWidgetShowsNetwork }
        case .temp: return { $0.islandWidgetShowsTemperature }
        case .music: return { $0.islandWidgetShowsMusic }
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

extension AppConfiguration {
    public var defaultIslandWidgetOrder: [IslandWidgetID] {
        [.cpu, .ram, .temp, .disk, .battery, .time, .date, .network, .music]
    }

    public var enabledIslandWidgets: [IslandWidgetID] {
        let order = islandWidgetOrder.compactMap { IslandWidgetID(rawValue: $0) }
        let effective = order.isEmpty ? defaultIslandWidgetOrder : order
        return effective
    }

    public var islandWidgetOrder: [String] {
        get {
            if let stored = UserDefaults.standard.string(forKey: "island.widget.order") {
                return stored.split(separator: ",").map(String.init)
            }
            return defaultIslandWidgetOrder.map(\.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue.joined(separator: ","), forKey: "island.widget.order")
        }
    }
}
