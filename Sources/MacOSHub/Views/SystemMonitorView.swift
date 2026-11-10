import Charts
import HubCore
import HubSystemMonitor
import SwiftUI

struct SystemMonitorView: View {
  @Bindable private var monitor = SystemMonitorService.shared

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        cpuSection
        memorySection
        diskSection
        temperatureSection
        processesTable
      }
      .padding(24)
    }
    .onAppear {
      monitor.updateInterval = AppConfiguration.shared.monitorUpdateInterval
      monitor.start()
    }
  }

  private var cpuSection: some View {
    HubCard {
      VStack(alignment: .leading, spacing: 12) {
        Text(LocalizedStringKey("metric.cpu")).font(.headline)
        Text(String(format: "%.1f%%", monitor.dashboard.cpu.totalUsage)).font(.system(size: 44, weight: .bold))
        Text("User \(String(format: "%.0f%%", monitor.dashboard.cpu.userUsage)) · System \(String(format: "%.0f%%", monitor.dashboard.cpu.systemUsage))")
          .font(.caption)
        Chart {
          ForEach(Array(monitor.dashboard.cpu.history.enumerated()), id: \.offset) { i, v in
            LineMark(x: .value("t", i), y: .value("%", v))
              .foregroundStyle(HubTheme.accentPurple)
          }
        }
        .frame(height: 120)
      }
    }
  }

  private var memorySection: some View {
    HubCard {
      VStack(alignment: .leading, spacing: 8) {
        Text(LocalizedStringKey("metric.memory")).font(.headline)
        ProgressView(value: monitor.dashboard.memory.usedFraction) {
          Text(ByteCountFormat.string(Int64(monitor.dashboard.memory.usedBytes)))
        }
        Text("Swap: \(ByteCountFormat.string(Int64(monitor.dashboard.memory.swapUsedBytes))) · \(monitor.dashboard.memory.pressure)")
          .font(.caption)
          .foregroundStyle(.secondary)
        Chart {
          ForEach(Array(monitor.dashboard.memory.history.enumerated()), id: \.offset) { i, v in
            AreaMark(x: .value("t", i), y: .value("%", v))
              .foregroundStyle(HubTheme.accentPurple.opacity(0.35))
          }
        }
        .frame(height: 80)
      }
    }
  }

  private var diskSection: some View {
    HubCard {
      VStack(alignment: .leading, spacing: 8) {
        Text(LocalizedStringKey("metric.disk")).font(.headline)
        Text(String(format: "%.0f%%", monitor.dashboard.disk.usedPercent)).font(.title)
        Text("\(ByteCountFormat.string(monitor.dashboard.disk.usedBytes)) / \(ByteCountFormat.string(monitor.dashboard.disk.totalBytes))")
        Text("↓ \(ByteCountFormat.rate(monitor.dashboard.network.bytesInPerSec)) · ↑ \(ByteCountFormat.rate(monitor.dashboard.network.bytesOutPerSec))")
          .font(.caption)
      }
    }
  }

  private var temperatureSection: some View {
    HubCard {
      VStack(alignment: .leading, spacing: 8) {
        Text(LocalizedStringKey("metric.temperature")).font(.headline)
        if monitor.dashboard.temperature.isAvailable, let c = monitor.dashboard.temperature.cpuCelsius {
          Text(String(format: "%.1f°C", c)).font(.title)
        } else {
          Text(LocalizedStringKey("temp.unavailable")).font(.title2).foregroundStyle(.secondary)
          if let key = monitor.dashboard.temperature.unavailableReasonKey {
            Text(LocalizedStringKey(key)).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
          }
        }
      }
    }
  }

  private var processesTable: some View {
    HubCard {
      VStack(alignment: .leading, spacing: 8) {
        Text(LocalizedStringKey("monitor.processes")).font(.headline)
        Table(monitor.dashboard.topProcesses) {
          TableColumn(String(localized: "monitor.column.process", bundle: .module)) { row in Text(row.name) }
          TableColumn("CPU") { row in Text(String(format: "%.1f%%", row.cpuPercent)) }
          TableColumn("RAM") { row in Text(ByteCountFormat.string(row.memoryBytes)) }
        }
        .frame(minHeight: 220)
      }
    }
  }
}

import HubSettings
