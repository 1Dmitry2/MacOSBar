import AppKit
import HubCore
import HubSettings
import SwiftUI

@MainActor
public final class MonitorSidebarController: NSObject {
    public static let shared = MonitorSidebarController()

    private var panel: NSPanel?
    private var hosting: NSHostingView<MonitorSidebarView>?
    private var screenObserver: NSObjectProtocol?

    public var isVisible: Bool { panel?.isVisible == true }

    private override init() {
        super.init()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.reposition() }
        }
    }

    public func applyConfiguration() {
        if AppConfiguration.shared.monitorSidebarEnabled {
            show()
        } else {
            hide()
        }
    }

    public func toggle() {
        if isVisible { hide() } else { show() }
    }

    public func show() {
        guard let screen = HubDisplayResolver.resolvedSidebarScreen() else { return }
        let config = AppConfiguration.shared
        let width = max(220, min(420, config.monitorSidebarWidth))
        let visible = screen.visibleFrame
        let height = visible.height - 40
        let x = config.monitorSidebarEdge == .left ? visible.minX + 8 : visible.maxX - width - 8
        let frame = CGRect(x: x, y: visible.minY + 20, width: width, height: height)

        if panel == nil {
            let hosting = NSHostingView(rootView: MonitorSidebarView())
            hosting.frame = CGRect(origin: .zero, size: frame.size)
            let panel = NSPanel(
                contentRect: frame,
                styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = config.monitorSidebarPinned ? .floating : .normal
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.isMovable = false
            panel.contentView = hosting
            self.panel = panel
            self.hosting = hosting
        }

        panel?.setFrame(frame, display: true)
        hosting?.frame = CGRect(origin: .zero, size: frame.size)
        panel?.orderFrontRegardless()
    }

    public func hide() {
        panel?.orderOut(nil)
    }

    public func stop() {
        panel?.close()
        panel = nil
        hosting = nil
    }

    public func reposition() {
        guard panel != nil, AppConfiguration.shared.monitorSidebarEnabled else { return }
        show()
    }
}

struct MonitorSidebarView: View {
    @Bindable private var metrics = SystemMetricsService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sidebarRow(title: "CPU", value: String(format: "%.1f%%", metrics.dashboard.cpu.totalUsage), history: metrics.dashboard.cpu.history)
            sidebarRow(title: "RAM", value: String(format: "%.1f%%", metrics.dashboard.memory.usedFraction * 100), history: metrics.dashboard.memory.history)
            sidebarRow(title: "SSD", value: String(format: "%.0f%%", metrics.dashboard.disk.usedPercent), history: [])
            if let temp = metrics.dashboard.temperature.cpuCelsius {
                sidebarRow(title: "TEMP", value: String(format: "%.0f°", temp), history: [])
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear { metrics.start() }
    }

    private func sidebarRow(title: String, value: String, history: [Double]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.bold())
            if !history.isEmpty {
                Sparkline(values: history)
                    .frame(height: 28)
            }
        }
    }
}

private struct Sparkline: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geo in
            let maxV = max(values.max() ?? 1, 1)
            Path { path in
                guard let first = values.first else { return }
                let step = geo.size.width / CGFloat(max(values.count - 1, 1))
                path.move(to: CGPoint(x: 0, y: geo.size.height * (1 - first / maxV)))
                for (idx, v) in values.enumerated() {
                    path.addLine(to: CGPoint(x: CGFloat(idx) * step, y: geo.size.height * (1 - v / maxV)))
                }
            }
            .stroke(Color.accentColor, lineWidth: 1.5)
        }
    }
}
