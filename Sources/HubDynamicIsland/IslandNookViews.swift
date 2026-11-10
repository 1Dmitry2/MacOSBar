import AppKit
import HubCore
import HubSettings
import HubSystemMonitor
import SwiftUI

struct IslandNookDockView: View {
    @Bindable var store: IslandNookStore
    let settings: DynamicIslandSettingsSnapshot
    let chrome: IslandChromeColors
    let accent: Color
    let actionsEnabled: Bool

    var body: some View {
        HStack(spacing: 6) {
            ForEach(IslandNookSection.dockCases) { section in
                if sectionVisible(section) {
                    dockItem(section)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            let capsule = Capsule(style: .continuous)
            if settings.liquidGlassEnabled {
                let tint = min(0.75, max(0.05, settings.liquidGlassTintOpacity))
                capsule
                    .fill(.clear)
                    .background(.thinMaterial, in: capsule)
                    .overlay(capsule.fill(Color.black.opacity(tint)))
                    .overlay(capsule.strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            } else {
                capsule
                    .fill(Color.black.opacity(min(settings.backgroundOpacity, 0.96)))
                    .overlay(capsule.strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
            }
        }
        .shadow(color: .black.opacity(0.28), radius: 8, y: 4)
    }

    private func sectionVisible(_ section: IslandNookSection) -> Bool {
        switch section {
        case .music:
            return settings.eventMediaEnabled
        case .monitor:
            return settings.eventSystemMetricsEnabled
        default:
            return true
        }
    }

    private func dockItem(_ section: IslandNookSection) -> some View {
        let selected = store.selectedSection == section
        return Button {
            guard actionsEnabled else { return }
            IslandInteractionSupport.activateForUserAction()
            store.selectSection(section)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: section.systemImage)
                    .font(.caption2.weight(.semibold))
                if selected {
                    Text(L10n.tr(section.localizationKey))
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, selected ? 10 : 8)
            .padding(.vertical, 6)
            .foregroundStyle(selected ? accent : chrome.foreground.opacity(0.82))
            .background(
                Capsule()
                    .fill(selected ? accent.opacity(0.18) : Color.white.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
        .disabled(!actionsEnabled)
    }
}

struct IslandNookPanelHost: View {
    @Bindable var store: IslandNookStore
    @Bindable var monitor: SystemMetricsService
    @Bindable var nowPlaying: NowPlayingMonitor
    @ObservedObject var clock: IslandClock
    let settings: DynamicIslandSettingsSnapshot
    let chrome: IslandChromeColors
    let actionsEnabled: Bool
    let contentMetrics: IslandContentMetrics

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Group {
                switch store.selectedSection {
                case .music:
                    IslandNookMusicPanel(nowPlaying: nowPlaying, chrome: chrome, actionsEnabled: actionsEnabled)
                case .monitor:
                    IslandNookMonitorPanel(
                        monitor: monitor,
                        clock: clock,
                        settings: settings,
                        chrome: chrome,
                        cpuHistory: store.cpuSparkline,
                        ramHistory: store.ramSparkline
                    )
                case .focus:
                    IslandNookFocusPanel(store: store, chrome: chrome, accent: .orange, actionsEnabled: actionsEnabled)
                case .calendar:
                    IslandNookCalendarPanel(chrome: chrome, accent: chrome.accent, actionsEnabled: actionsEnabled)
                case .tasks:
                    IslandNookMonitorPanel(
                        monitor: monitor,
                        clock: clock,
                        settings: settings,
                        chrome: chrome,
                        cpuHistory: store.cpuSparkline,
                        ramHistory: store.ramSparkline
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: contentMetrics.scrollableMaxHeight, alignment: .topLeading)
        .onAppear { sampleMetrics() }
        .onChange(of: monitor.dashboard.cpu.totalUsage) { _, _ in sampleMetrics() }
        .onChange(of: monitor.dashboard.memory.usedFraction) { _, _ in sampleMetrics() }
    }

    private func sampleMetrics() {
        store.recordMetricSamples(
            cpu: monitor.dashboard.cpu.totalUsage,
            ramFraction: monitor.dashboard.memory.usedFraction
        )
    }
}

private enum IslandMusicPanelTab: String, CaseIterable {
    case output
    case applications
}

private struct IslandNookMusicPanel: View {
    @Bindable var nowPlaying: NowPlayingMonitor
    @Bindable private var audioRoutes = IslandAudioOutputService.shared
    let chrome: IslandChromeColors
    let actionsEnabled: Bool
    @Environment(\.islandContentMetrics) private var layout
    @State private var tab: IslandMusicPanelTab = .output
    @State private var showAudioExtras = false

    var body: some View {
        VStack(alignment: .leading, spacing: layout.sectionSpacing) {
            HStack(alignment: .top, spacing: 10) {
                albumArt
                VStack(alignment: .leading, spacing: 4) {
                    Text(nowPlaying.title ?? L10n.tr("island.preview.music.title"))
                        .font(layout.titleFont)
                        .lineLimit(layout.titleLineLimit)
                        .minimumScaleFactor(0.85)
                    Text(nowPlaying.artist ?? L10n.tr("island.preview.music.artist"))
                        .font(layout.artistFont)
                        .foregroundStyle(chrome.foreground.opacity(0.65))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: layout.transportSpacing) {
                controlIcon("list.bullet") {
                    NSWorkspace.shared.launchApplication("Music")
                }
                controlIcon("shuffle") {
                    IslandMediaTransport.toggleShuffle()
                }
                controlIcon("backward.fill") { IslandMediaTransport.skipBackward() }
                playButton
                controlIcon("forward.fill") { IslandMediaTransport.skipForward() }
                controlIcon("macbook", accent: showAudioExtras) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        showAudioExtras.toggle()
                    }
                    if showAudioExtras { audioRoutes.refresh() }
                }
            }
            .frame(maxWidth: .infinity)

            if showAudioExtras {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("", selection: $tab) {
                        Text(L10n.tr("island.nook.music.output")).tag(IslandMusicPanelTab.output)
                        Text(L10n.tr("island.nook.music.applications")).tag(IslandMusicPanelTab.applications)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    tabBody
                }
                .padding(.top, 4)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .foregroundStyle(chrome.foreground.opacity(0.94))
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: showAudioExtras)
        .onAppear { audioRoutes.refresh() }
    }

    @ViewBuilder
    private var tabBody: some View {
        switch tab {
        case .output:
            VStack(spacing: 0) {
                ForEach(audioRoutes.devices) { device in
                    outputRow(device)
                }
            }
        case .applications:
            HStack(spacing: 10) {
                Image(systemName: "music.note.list")
                    .foregroundStyle(chrome.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.tr("island.nook.music.nowPlayingApp"))
                        .font(.caption.weight(.semibold))
                    Text(nowPlaying.title ?? L10n.tr("island.nook.music.systemPlayer"))
                        .font(.caption2)
                        .foregroundStyle(chrome.foreground.opacity(0.65))
                }
                Spacer()
            }
            .padding(.vertical, 6)
        }
    }

    private func outputRow(_ device: AudioOutputDevice) -> some View {
        let selected = audioRoutes.defaultDeviceID == device.id
        return Button {
            guard actionsEnabled else { return }
            IslandInteractionSupport.activateForUserAction()
            audioRoutes.setDefaultOutput(device.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: device.systemImage)
                    .font(.body.weight(.semibold))
                    .frame(width: 24)
                Text(device.name)
                    .font(.subheadline)
                    .lineLimit(1)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(chrome.accent)
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!actionsEnabled)
    }

    private var playButton: some View {
        Button {
            guard actionsEnabled else { return }
            IslandMediaTransport.togglePlayPause()
        } label: {
            Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                .font(.title3.weight(.semibold))
                .frame(width: 46, height: 46)
                .background(Color.white.opacity(0.14), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!actionsEnabled)
    }

    private func controlIcon(_ icon: String, accent highlight: Bool = false, _ action: @escaping () -> Void = {}) -> some View {
        Button {
            guard actionsEnabled else { return }
            IslandInteractionSupport.activateForUserAction()
            action()
        } label: {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .frame(width: 30, height: 30)
                .background(highlight ? Color.white.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!actionsEnabled)
    }

    @ViewBuilder
    private var albumArt: some View {
        Group {
            if let artwork = nowPlaying.artwork {
                Image(nsImage: artwork).resizable().scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(chrome.accent.opacity(0.35))
                    .overlay(Image(systemName: "music.note").font(.title3))
            }
        }
        .frame(width: layout.albumArtSize, height: layout.albumArtSize)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct IslandNookMonitorPanel: View {
    @Bindable var monitor: SystemMetricsService
    @ObservedObject var clock: IslandClock
    let settings: DynamicIslandSettingsSnapshot
    let chrome: IslandChromeColors
    let cpuHistory: [Double]
    let ramHistory: [Double]
    @Environment(\.islandContentMetrics) private var layout

    private var metricColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: IslandNookLayout.tileSpacing), count: layout.metricColumns)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IslandNookLayout.sectionSpacing) {
            if settings.widgetShowsTime || settings.widgetShowsDate {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if settings.widgetShowsTime {
                        Text(clock.timeString)
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                    }
                    if settings.widgetShowsDate {
                        Text(clock.dateString)
                            .font(.caption)
                            .foregroundStyle(chrome.foreground.opacity(0.72))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
            }
            LazyVGrid(columns: metricColumns, alignment: .leading, spacing: IslandNookLayout.tileSpacing) {
                if settings.widgetShowsCPU {
                    IslandNookMetricTile {
                        metricCardContent(
                            title: "CPU",
                            value: String(format: "%.0f%%", monitor.dashboard.cpu.totalUsage),
                            tint: HubTheme.successGreen,
                            history: cpuHistory
                        )
                    }
                }
                if settings.widgetShowsRAM {
                    IslandNookMetricTile {
                        metricCardContent(
                            title: "RAM",
                            value: String(format: "%.0f%%", monitor.dashboard.memory.usedFraction * 100),
                            tint: Color.orange,
                            history: ramHistory
                        )
                    }
                }
                if settings.widgetShowsBattery, let level = monitor.dashboard.power.levelPercent {
                    IslandNookMetricTile {
                        compactMetricContent(
                            title: L10n.tr("island.widget.battery"),
                            value: String(format: "%.0f%%", level),
                            systemImage: "battery.100"
                        )
                    }
                }
                if settings.widgetShowsDisk {
                    IslandNookMetricTile {
                        compactMetricContent(
                            title: L10n.tr("island.widget.disk"),
                            value: String(format: "%.0f%%", monitor.dashboard.disk.usedPercent),
                            systemImage: "internaldrive"
                        )
                    }
                }
                if settings.widgetShowsNetwork {
                    IslandNookMetricTile {
                        compactMetricContent(
                            title: L10n.tr("island.widget.network"),
                            value: networkSummary,
                            systemImage: "network"
                        )
                    }
                }
                if settings.widgetShowsTemperature {
                    let value: String = {
                        if let temp = monitor.dashboard.temperature.cpuCelsius {
                            return String(format: "%.0f°", temp)
                        }
                        return "—"
                    }()
                    IslandNookMetricTile {
                        compactMetricContent(
                            title: L10n.tr("island.widget.temp"),
                            value: value,
                            systemImage: "thermometer.medium"
                        )
                    }
                }
            }
        }
        .foregroundStyle(chrome.foreground.opacity(0.94))
    }

    private var networkSummary: String {
        let down = ByteCountFormat.string(Int64(monitor.dashboard.network.bytesInPerSec))
        let up = ByteCountFormat.string(Int64(monitor.dashboard.network.bytesOutPerSec))
        return "↓\(down) ↑\(up)"
    }

    private func compactMetricContent(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
    }

    private func metricCardContent(title: String, value: String, tint: Color, history: [Double]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: title == "CPU" ? "cpu" : "memorychip")
                .font(.caption.weight(.semibold))
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
            SparklineView(values: history, color: tint)
                .frame(height: 26)
        }
    }
}

private struct SparklineView: View {
    let values: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let points = normalizedPoints(in: geo.size)
            Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard !values.isEmpty else { return [] }
        let maxV = max(values.max() ?? 1, 1)
        let stepX = size.width / CGFloat(max(values.count - 1, 1))
        return values.enumerated().map { index, value in
            let x = CGFloat(index) * stepX
            let y = size.height - (CGFloat(value / maxV) * size.height)
            return CGPoint(x: x, y: y)
        }
    }
}

private struct IslandNookFocusPanel: View {
    @Bindable var store: IslandNookStore
    let chrome: IslandChromeColors
    let accent: Color
    let actionsEnabled: Bool
    @Environment(\.islandContentMetrics) private var layout

    var body: some View {
        VStack(alignment: .leading, spacing: layout.sectionSpacing) {
            HStack(alignment: .center, spacing: 8) {
                focusModePills
                Spacer(minLength: 8)
                Text(timeLabel)
                    .font(.system(size: layout.focusTimeFontSize, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(accent)
            }

            if store.focusRunning {
                ProgressView(
                    value: Double(focusSessionTotal - focusProgressRemaining),
                    total: Double(focusSessionTotal)
                )
                .progressViewStyle(.linear)
                .tint(accent)
            } else {
                IslandFocusMinuteDial(minutes: $store.focusDurationMinutes, accent: accent)
                    .disabled(!actionsEnabled)
            }

            HStack(spacing: 10) {
                Button {
                    guard actionsEnabled else { return }
                    IslandInteractionSupport.activateForUserAction()
                    if store.focusRunning {
                        store.stopFocusTimer()
                    } else {
                        store.startFocusTimer()
                    }
                } label: {
                    Text(store.focusRunning ? L10n.tr("island.nook.focus.stop") : L10n.tr("island.nook.focus.start"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .background(accent.opacity(0.24), in: Capsule(style: .continuous))
                .disabled(!actionsEnabled)

                focusIconButton("speaker.wave.2.fill") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.sound")!)
                }
                focusIconButton("stopwatch") {
                    guard actionsEnabled, !store.focusRunning else { return }
                    store.focusDurationMinutes = 25
                }
            }
        }
        .foregroundStyle(chrome.foreground.opacity(0.95))
    }

    private var focusSessionTotal: Int {
        max(60, store.focusDurationMinutes * 60)
    }

    private var focusProgressRemaining: Int {
        store.focusRemainingSeconds ?? focusSessionTotal
    }

    private var focusModePills: some View {
        HStack(spacing: 6) {
            focusPill(L10n.tr("island.nook.focus.concentration"), .concentration)
            focusPill(L10n.tr("island.nook.focus.break"), .breakTime)
        }
    }

    private func focusPill(_ title: String, _ mode: IslandFocusMode) -> some View {
        let selected = store.focusMode == mode
        return Button {
            guard actionsEnabled else { return }
            store.focusMode = mode
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(selected ? accent.opacity(0.28) : Color.white.opacity(0.08), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!actionsEnabled || store.focusRunning)
    }

    private func focusIconButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            guard actionsEnabled else { return }
            IslandInteractionSupport.activateForUserAction()
            action()
        } label: {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!actionsEnabled)
    }

    private var timeLabel: String {
        if let remaining = store.focusRemainingSeconds {
            let m = remaining / 60
            let s = remaining % 60
            return String(format: "%d:%02d", m, s)
        }
        return String(format: "%d:00", store.focusDurationMinutes)
    }
}

private struct IslandNookCalendarPanel: View {
  @Bindable private var calendar = IslandCalendarReader.shared
    let chrome: IslandChromeColors
    let accent: Color
    let actionsEnabled: Bool
    @State private var month = Calendar.current.component(.month, from: Date())
    @State private var year = Calendar.current.component(.year, from: Date())

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                if calendar.events.isEmpty {
                    Label(L10n.tr("island.nook.calendar.empty"), systemImage: "calendar")
                        .font(.subheadline.weight(.semibold))
                    Text(calendarHint)
                        .font(.caption)
                        .foregroundStyle(chrome.foreground.opacity(0.65))
                } else {
                    ForEach(calendar.events.prefix(3)) { event in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Text(eventTime(event))
                                .font(.caption2)
                                .foregroundStyle(chrome.foreground.opacity(0.65))
                        }
                    }
                }
                HStack(spacing: 8) {
                    Button(L10n.tr("island.nook.calendar.access")) {
                        IslandInteractionSupport.activateForUserAction()
                        calendar.requestAccessAndReload()
                    }
                    .buttonStyle(.borderless)
                    .disabled(!actionsEnabled)
                    Button(L10n.tr("island.nook.calendar.new")) {
                        IslandInteractionSupport.activateForUserAction()
                        NSWorkspace.shared.open(URL(string: "x-apple-cal://")!)
                    }
                    .buttonStyle(.borderless)
                    .disabled(!actionsEnabled)
                }
                .font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            monthGrid
        }
        .foregroundStyle(chrome.foreground.opacity(0.94))
        .onAppear {
            calendar.reloadEvents()
            if calendar.events.isEmpty, calendar.authorization == .notDetermined {
                calendar.requestAccessAndReload()
            }
        }
    }

    private var calendarHint: String {
        switch calendar.authorization {
        case .fullAccess, .authorized:
            return L10n.tr("island.nook.calendar.hint")
        case .denied, .restricted, .writeOnly:
            return L10n.tr("island.nook.calendar.denied")
        default:
            return L10n.tr("island.nook.calendar.needAccess")
        }
    }

    private func eventTime(_ event: IslandCalendarEvent) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        if event.isAllDay {
            f.dateStyle = .medium
            f.timeStyle = .none
        } else {
            f.dateStyle = .none
            f.timeStyle = .short
        }
        return f.string(from: event.start)
    }

    private var monthGrid: some View {
        let days = daysInMonth()
        return VStack(spacing: 4) {
            Text(monthTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
                ForEach(days, id: \.self) { day in
                    Text(day > 0 ? "\(day)" : " ")
                        .font(.caption2.monospacedDigit())
                        .frame(width: 20, height: 20)
                        .background(dayIsToday(day) ? accent : Color.clear, in: Circle())
                }
            }
        }
    }

    private var monthTitle: String {
        let comps = DateComponents(year: year, month: month)
        let date = Calendar.current.date(from: comps) ?? Date()
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("LLLL")
        return f.string(from: date).uppercased()
    }

    private func daysInMonth() -> [Int] {
        let comps = DateComponents(year: year, month: month, day: 1)
        guard let start = Calendar.current.date(from: comps),
              let range = Calendar.current.range(of: .day, in: .month, for: start) else { return [] }
        let weekday = Calendar.current.component(.weekday, from: start)
        let leading = max(0, weekday - 1)
        var result = Array(repeating: 0, count: leading)
        result.append(contentsOf: range.map { $0 })
        return result
    }

    private func dayIsToday(_ day: Int) -> Bool {
        guard day > 0 else { return false }
        let now = Date()
        let cal = Calendar.current
        return cal.component(.day, from: now) == day
            && cal.component(.month, from: now) == month
            && cal.component(.year, from: now) == year
    }
}

private struct IslandNookTasksPanel: View {
    @Bindable var store: IslandNookStore
    let chrome: IslandChromeColors
    let accent: Color
    let actionsEnabled: Bool
    @State private var draft = ""
    @FocusState private var draftFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if store.tasks.isEmpty {
                Text(L10n.tr("island.nook.tasks.empty"))
                    .font(.subheadline.weight(.semibold))
            } else {
                ForEach(store.tasks.prefix(4)) { task in
                    Button {
                        guard actionsEnabled else { return }
                        IslandInteractionSupport.activateForUserAction()
                        store.toggleTask(task.id)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.isDone ? accent : chrome.foreground.opacity(0.5))
                            Text(task.title)
                                .strikethrough(task.isDone)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack(spacing: 8) {
                TextField(L10n.tr("island.nook.tasks.placeholder"), text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .focused($draftFocused)
                    .disabled(!actionsEnabled)
                    .onSubmit(addDraft)
                    .onTapGesture {
                        IslandInteractionSupport.activateForUserAction()
                        draftFocused = true
                    }
                Button(action: addDraft) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(accent)
                }
                .buttonStyle(.borderless)
                .disabled(!actionsEnabled)
            }
        }
        .foregroundStyle(chrome.foreground.opacity(0.94))
    }

    private func addDraft() {
        guard actionsEnabled else { return }
        IslandInteractionSupport.activateForUserAction()
        store.addTask(title: draft)
        draft = ""
    }
}
