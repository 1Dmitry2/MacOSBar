import AppKit
import HubCore
import HubDiagnostics
import HubSettings
import HubSystemMonitor
import SwiftUI

public final class DynamicIslandPanel: NSPanel {
    public init(content: NSView, frame: CGRect) {
        super.init(
            contentRect: frame,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .statusBar + 2
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovable = false
        isMovableByWindowBackground = false
        contentView = content
    }

    public override var canBecomeKey: Bool { true }
}

@MainActor
public final class DynamicIslandController: NSObject {
    public static let shared = DynamicIslandController()

    private var panel: DynamicIslandPanel?
    private var hosting: NSHostingView<IslandRootView>?
    private var layout: NotchLayout?
    private var expanded = false
    private let log = HubLogger.log(.island)
    private var screenObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?

    public var isRunning: Bool { panel != nil }

    private override init() {
        super.init()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.reposition(animated: false) }
        }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.reposition(animated: false) }
        }
    }

    public func startIfEnabled() {
        guard AppConfiguration.shared.dynamicIslandEnabled else {
            stop()
            return
        }
        guard panel == nil, let layout = NotchLayout.detect() else { return }

        self.layout = layout
        let initialFrame = layout.frame(expanded: false)
        let root = IslandRootView(layout: layout, expanded: expanded)
        let hosting = NSHostingView(rootView: root)
        hosting.frame = CGRect(origin: .zero, size: initialFrame.size)

        let panel = DynamicIslandPanel(content: hosting, frame: initialFrame)
        self.hosting = hosting
        self.panel = panel
        panel.orderFrontRegardless()
        log.info("Dynamic Island shown on \(layout.screen.localizedName)")
    }

    public func stop() {
        panel?.close()
        panel = nil
        hosting = nil
        layout = nil
        expanded = false
    }

    public func toggleExpanded() {
        guard panel != nil else { return }
        expanded.toggle()
        reposition(animated: true)
        reloadContent()
    }

    public func reposition(animated: Bool) {
        guard let panel, let fresh = NotchLayout.detect(screen: HubDisplayResolver.resolvedIslandScreen()) else {
            if panel == nil, AppConfiguration.shared.dynamicIslandEnabled { startIfEnabled() }
            return
        }
        layout = fresh
        let frame = fresh.frame(expanded: expanded)
        hosting?.frame = CGRect(origin: .zero, size: frame.size)
        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.32
                panel.animator().setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }
        panel.orderFrontRegardless()
    }

    private func reloadContent() {
        guard let layout, let hosting else { return }
        hosting.rootView = IslandRootView(layout: layout, expanded: expanded)
    }

    public func applySettingsChange() {
        if AppConfiguration.shared.dynamicIslandEnabled {
            if panel == nil {
                startIfEnabled()
            } else {
                layout = NotchLayout.detect()
                reposition(animated: true)
                reloadContent()
            }
        } else {
            stop()
        }
    }
}

struct IslandRootView: View {
    @ObservedObject private var clock = IslandClock()
    @Bindable private var monitor = SystemMetricsService.shared
    @Bindable private var config = AppConfiguration.shared
  let layout: NotchLayout
    let expanded: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: expanded ? 26 : 22, style: .continuous)
                .fill(.black.opacity(0.88))
            if expanded {
                expandedContent
            } else {
                compactContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onTapGesture { DynamicIslandController.shared.toggleExpanded() }
        .onAppear { monitor.start() }
    }

    private var compactContent: some View {
        HStack(spacing: 12) {
            if config.islandWidgetShowsTime {
                Text(clock.timeString)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            if config.islandWidgetShowsCPU {
                metricChip(icon: "cpu", value: String(format: "%.0f%%", monitor.dashboard.cpu.totalUsage))
            }
            if config.islandWidgetShowsRAM {
                metricChip(icon: "memorychip", value: String(format: "%.0f%%", monitor.dashboard.memory.usedFraction * 100))
            }
            if config.islandWidgetShowsBattery, let level = monitor.dashboard.power.levelPercent {
                metricChip(
                    icon: monitor.dashboard.power.isOnBattery ? "battery.50" : "powerplug",
                    value: String(format: "%.0f%%", level)
                )
            }
        }
        .foregroundStyle(.white.opacity(0.92))
        .padding(.horizontal, 14)
    }

    private var expandedContent: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                if config.islandWidgetShowsTime { Text(clock.timeString).font(.title3.bold()) }
                if config.islandWidgetShowsDate { Text(clock.dateString).font(.caption) }
                Spacer()
                if config.islandWidgetShowsNetwork {
                    metricChip(icon: "arrow.down.circle", value: rate(monitor.dashboard.network.bytesInPerSec))
                    metricChip(icon: "arrow.up.circle", value: rate(monitor.dashboard.network.bytesOutPerSec))
                }
            }
            HStack(spacing: 14) {
                if config.islandWidgetShowsCPU {
                    islandStat(title: "CPU", value: String(format: "%.1f%%", monitor.dashboard.cpu.totalUsage))
                }
                if config.islandWidgetShowsRAM {
                    islandStat(title: "RAM", value: String(format: "%.1f%%", monitor.dashboard.memory.usedFraction * 100))
                }
                if config.islandWidgetShowsDisk {
                    islandStat(title: "SSD", value: String(format: "%.0f%%", monitor.dashboard.disk.usedPercent))
                }
                if config.islandWidgetShowsBattery, let level = monitor.dashboard.power.levelPercent {
                    islandStat(title: "BAT", value: String(format: "%.0f%%", level))
                }
            }
        }
        .foregroundStyle(.white.opacity(0.94))
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
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

final class IslandClock: ObservableObject {
    @Published var timeString = ""
    @Published var dateString = ""
    private var timer: Timer?

    init() {
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
    }

    private func tick() {
        let now = Date()
        let time = DateFormatter()
        time.dateFormat = "HH:mm"
        let date = DateFormatter()
        date.dateStyle = .medium
        date.timeStyle = .none
        timeString = time.string(from: now)
        dateString = date.string(from: now)
    }
}
