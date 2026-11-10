import HubCleaner
import HubCore
import HubSettings
import HubSystemMonitor
import SwiftUI

struct OverviewView: View {
    @Bindable private var monitor = SystemMonitorService.shared
    private let summary = MacSummary.current()
    @Bindable private var config = AppConfiguration.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    metricCard(title: "CPU", value: String(format: "%.1f%%", monitor.dashboard.cpu.totalUsage), subtitle: "\(monitor.dashboard.cpu.coreCount) cores") {
                        Sparkline(values: monitor.dashboard.cpu.history)
                    }
                    metricCard(title: "Memory", value: ByteCountFormat.string(Int64(monitor.dashboard.memory.usedBytes)), subtitle: "of \(ByteCountFormat.string(Int64(monitor.dashboard.memory.totalBytes)))") {
                        ProgressView(value: monitor.dashboard.memory.usedFraction)
                    }
                    metricCard(title: "Disk", value: String(format: "%.0f%%", monitor.dashboard.disk.usedPercent), subtitle: monitor.dashboard.disk.volumeName) {
                        ProgressView(value: monitor.dashboard.disk.usedPercent / 100)
                    }
                    metricCard(title: "Temperature", value: "Unavailable", subtitle: "No public Apple Silicon API") {
                        Text("—")
                            .foregroundStyle(.secondary)
                    }
                }
                modulesStatusCard
            }
            .padding(24)
        }
        .navigationTitle("Overview")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(summary.hostName)
                .font(.largeTitle.bold())
            Text("\(summary.osVersion) · \(summary.chipName) · \(String(format: "%.0f", summary.physicalMemoryGB)) GB RAM")
                .foregroundStyle(.secondary)
        }
    }

    private func metricCard<Content: View>(title: String, value: String, subtitle: String, @ViewBuilder chart: () -> Content) -> some View {
        HubCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.headline)
                Text(value).font(.title2.bold())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
                chart()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var modulesStatusCard: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Modules").font(.headline)
                ForEach(HubModuleID.allCases) { module in
                    HStack {
                        Text(module.displayName)
                        Spacer()
                        Image(systemName: config.isModuleEnabled(module) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(config.isModuleEnabled(module) ? HubTheme.successGreen : .secondary)
                    }
                }
                HStack {
                    Text("Dynamic Island")
                    Spacer()
                    Text(config.dynamicIslandEnabled ? "Active" : "Off")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Uptime")
                    Spacer()
                    Text(formatUptime(monitor.dashboard.uptime))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func formatUptime(_ t: TimeInterval) -> String {
        let d = Int(t) / 86_400
        let h = (Int(t) % 86_400) / 3600
        let m = (Int(t) % 3600) / 60
        return "\(d)d \(h)h \(m)m"
    }
}

struct Sparkline: View {
    let values: [Double]
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let maxV = max(values.max() ?? 1, 1)
            Path { path in
                guard values.count > 1 else { return }
                for (i, v) in values.enumerated() {
                    let x = w * CGFloat(i) / CGFloat(values.count - 1)
                    let y = h - (CGFloat(v / maxV) * h)
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(HubTheme.accentPurple, lineWidth: 2)
        }
        .frame(height: 40)
    }
}
