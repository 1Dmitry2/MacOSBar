import HubCore
import HubSystemMonitor
import SwiftUI

struct SystemMonitorView: View {
    @Bindable private var monitor = SystemMonitorService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    cpuCard
                    memoryCard
                    diskCard
                    networkCard
                    temperatureCard
                    powerCard
                }
                processesTable
            }
            .padding(24)
        }
        .navigationTitle("System Monitor")
        .onAppear { monitor.start() }
    }

    private var cpuCard: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("CPU").font(.headline)
                Text(String(format: "%.1f%%", monitor.dashboard.cpu.totalUsage)).font(.title)
                Text("User \(String(format: "%.0f%%", monitor.dashboard.cpu.userUsage)) · System \(String(format: "%.0f%%", monitor.dashboard.cpu.systemUsage))")
                    .font(.caption)
                Sparkline(values: monitor.dashboard.cpu.history)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var memoryCard: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Memory").font(.headline)
                Text(ByteCountFormat.string(Int64(monitor.dashboard.memory.usedBytes))).font(.title2.bold())
                ProgressView(value: monitor.dashboard.memory.usedFraction)
                Text("Pressure: \(monitor.dashboard.memory.pressure) · Swap activity tracked")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var diskCard: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Disk").font(.headline)
                Text(String(format: "%.0f%% used", monitor.dashboard.disk.usedPercent)).font(.title2.bold())
                Text("\(ByteCountFormat.string(monitor.dashboard.disk.freeBytes)) free of \(ByteCountFormat.string(monitor.dashboard.disk.totalBytes))")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var networkCard: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Network (\(monitor.dashboard.network.interfaceName))").font(.headline)
                Text("↓ \(ByteCountFormat.rate(monitor.dashboard.network.bytesInPerSec))")
                Text("↑ \(ByteCountFormat.rate(monitor.dashboard.network.bytesOutPerSec))")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var temperatureCard: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Temperature").font(.headline)
                Text("Unavailable")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Apple does not expose CPU temperature via public APIs on Apple Silicon.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var powerCard: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Power").font(.headline)
                if let pct = monitor.dashboard.power.levelPercent {
                    Text(String(format: "%.0f%%", pct))
                    if let t = monitor.dashboard.power.timeRemaining {
                        Text(t).font(.caption).foregroundStyle(.secondary)
                    }
                } else {
                    Text("On AC / Desktop").foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var processesTable: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Top processes (by memory)").font(.headline)
                Table(monitor.dashboard.topProcesses) {
                    TableColumn("Process") { row in Text(row.name) }
                    TableColumn("CPU") { row in Text(String(format: "%.1f%%", row.cpuPercent)) }
                    TableColumn("Memory") { row in Text(ByteCountFormat.string(row.memoryBytes)) }
                }
                .frame(minHeight: 200)
            }
        }
    }
}
