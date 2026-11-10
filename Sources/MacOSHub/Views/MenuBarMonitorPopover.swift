import AppKit
import Charts
import HubCore
import HubSettings
import HubSystemMonitor
import SwiftUI

struct MenuBarMonitorPopover: View {
    @Bindable private var metrics = SystemMetricsService.shared
    @Environment(\.locale) private var locale

    var openMainWindow: (HubDestination?) -> Void
    var quit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            metricsSection

            Divider()

            VStack(spacing: 6) {
                actionRow(titleKey: "menubar.open", icon: "macwindow") { openMainWindow(nil) }
                actionRow(dest: .overview)
                actionRow(dest: .smartCleaner)
                actionRow(dest: .systemMonitor)
            }

            Divider()

            actionRow(titleKey: "menubar.quit", icon: "power", destructive: true) { quit() }
        }
        .padding(14)
        .frame(width: 300)
        .onAppear { metrics.start() }
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            metricLine(L10n.tr("metric.cpu", locale: locale), value: String(format: "%.1f%%", metrics.dashboard.cpu.totalUsage), history: metrics.dashboard.cpu.history)
            metricLine(L10n.tr("metric.memory", locale: locale), value: String(format: "%.1f%%", metrics.dashboard.memory.usedFraction * 100), history: metrics.dashboard.memory.history)
            metricLine(L10n.tr("metric.disk", locale: locale), value: String(format: "%.0f%%", metrics.dashboard.disk.usedPercent), history: [])
            if let c = metrics.dashboard.temperature.cpuCelsius {
                metricLine(L10n.tr("metric.temperature", locale: locale), value: String(format: "%.0f°", c), history: [])
            }
        }
    }

    private func actionRow(dest: HubDestination) -> some View {
        actionRow(titleKey: dest.localizationKey, icon: dest.systemImage) { openMainWindow(dest) }
    }

    private func actionRow(
        titleKey: String,
        icon: String,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
            dismissPopover()
        } label: {
            Label(L10n.tr(titleKey, locale: locale), systemImage: icon)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(destructive ? Color.red.opacity(0.15) : Color.primary.opacity(0.06))
                }
        }
        .buttonStyle(.plain)
    }

    private func dismissPopover() {
        for window in NSApp.windows where window.className.contains("StatusBar") || window.level == .popUpMenu {
            window.orderOut(nil)
        }
    }

    private func metricLine(_ title: String, value: String, history: [Double]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(value).font(.headline).monospacedDigit()
            }
            if !history.isEmpty {
                Chart {
                    ForEach(Array(history.enumerated()), id: \.offset) { i, v in
                        LineMark(x: .value("t", i), y: .value("%", v))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .frame(height: 40)
            }
        }
    }
}
