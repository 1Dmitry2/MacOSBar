import AppKit
import HubDiagnostics
import HubSettings
import HubSystemMonitor
import SwiftUI

public final class DynamicIslandPanel: NSPanel {
    public init(content: NSView) {
        super.init(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        contentView = content
    }

    public override var canBecomeKey: Bool { true }
}

@MainActor
public final class DynamicIslandController: NSObject {
    public static let shared = DynamicIslandController()

    private var panel: DynamicIslandPanel?
    private var expanded = false
    private let log = HubLogger.log(.island)

    public func startIfEnabled() {
        guard AppConfiguration.shared.dynamicIslandEnabled else {
            stop()
            return
        }
        guard panel == nil, let layout = NotchLayout.detect() else { return }
        let hosting = NSHostingView(rootView: IslandRootView(layout: layout))
        hosting.frame = CGRect(origin: layout.islandOrigin, size: layout.compactSize)
        let panel = DynamicIslandPanel(content: hosting)
        panel.setFrame(hosting.frame, display: true)
        self.panel = panel
        panel.orderFrontRegardless()
        log.info("Dynamic Island panel shown")
    }

    public func stop() {
        panel?.close()
        panel = nil
    }

    public func toggleExpanded() {
        guard let panel, var layout = NotchLayout.detect() else { return }
        expanded.toggle()
        let size = expanded ? layout.expandedSize : layout.compactSize
        layout.islandOrigin.x = layout.screenFrame.midX - size.width / 2
        let frame = CGRect(origin: layout.islandOrigin, size: size)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            panel.animator().setFrame(frame, display: true)
        }
    }
}

struct IslandRootView: View {
    @ObservedObject private var clock = IslandClock()
    @Bindable private var monitor = SystemMonitorService.shared
    let layout: NotchLayout

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.black.opacity(0.88))
            HStack(spacing: 16) {
                Text(clock.timeString)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Divider().frame(height: 20).opacity(0.3)
                HStack(spacing: 8) {
                    Image(systemName: "cpu")
                    Text(String(format: "%.0f%%", monitor.dashboard.cpu.totalUsage))
                }
                .font(.caption)
                HStack(spacing: 8) {
                    Image(systemName: "memorychip")
                    Text(String(format: "%.0f%%", monitor.dashboard.memory.usedFraction * 100))
                }
                .font(.caption)
                if let level = monitor.dashboard.power.levelPercent {
                    HStack(spacing: 4) {
                        Image(systemName: monitor.dashboard.power.isOnBattery ? "battery.50" : "powerplug")
                        Text(String(format: "%.0f%%", level))
                    }
                    .font(.caption2)
                }
            }
            .foregroundStyle(.white.opacity(0.92))
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onTapGesture { DynamicIslandController.shared.toggleExpanded() }
        .onAppear { monitor.start() }
    }
}

final class IslandClock: ObservableObject {
    @Published var timeString = ""
    private var timer: Timer?

    init() {
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
    }

    private func tick() {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        timeString = f.string(from: Date())
    }
}
