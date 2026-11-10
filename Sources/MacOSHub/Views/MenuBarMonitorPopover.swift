import Charts
import HubCore
import HubSettings
import HubSystemMonitor
import SwiftUI

struct MenuBarMonitorPopover: View {
    @Bindable private var metrics = SystemMetricsService.shared
    @Environment(\.locale) private var locale
    var openSystemMonitor: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            metricLine(L10n.tr("metric.cpu", locale: locale), value: String(format: "%.1f%%", metrics.dashboard.cpu.totalUsage), history: metrics.dashboard.cpu.history)
            metricLine(L10n.tr("metric.memory", locale: locale), value: String(format: "%.1f%%", metrics.dashboard.memory.usedFraction * 100), history: metrics.dashboard.memory.history)
            metricLine(L10n.tr("metric.disk", locale: locale), value: String(format: "%.0f%%", metrics.dashboard.disk.usedPercent), history: [])
            if let c = metrics.dashboard.temperature.cpuCelsius {
                metricLine(L10n.tr("metric.temperature", locale: locale), value: String(format: "%.0f°", c), history: [])
            }
            Button(L10n.tr("nav.systemMonitor", locale: locale), action: openSystemMonitor)
                .buttonStyle(.borderedProminent)
        }
        .padding(14)
        .frame(width: 280)
        .onAppear { metrics.start() }
    }

    private func metricLine(_ title: String, value: String, history: [Double]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(value).font(.headline)
            }
            if !history.isEmpty {
                Chart {
                    ForEach(Array(history.enumerated()), id: \.offset) { i, v in
                        LineMark(x: .value("t", i), y: .value("%", v))
                    }
                }
                .frame(height: 42)
            }
        }
    }
}
