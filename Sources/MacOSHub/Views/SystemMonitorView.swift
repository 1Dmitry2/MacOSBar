import Charts
import HubCore
import HubSettings
import HubSystemMonitor
import SwiftUI

struct SystemMonitorView: View {
  @Bindable private var monitor = SystemMonitorService.shared
  @Environment(\.locale) private var locale

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
      if !monitor.isRunning { monitor.start() }
    }
  }

  private var cpuSection: some View {
    HubCard {
      VStack(alignment: .leading, spacing: 12) {
        LText("metric.cpu").font(.headline)
        Text(String(format: "%.1f%%", monitor.dashboard.cpu.totalUsage)).font(.system(size: 44, weight: .bold))
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
        LText("metric.memory").font(.headline)
        ProgressView(value: monitor.dashboard.memory.usedFraction) {
          Text(ByteCountFormat.string(Int64(monitor.dashboard.memory.usedBytes)))
        }
        Text("Swap: \(ByteCountFormat.string(Int64(monitor.dashboard.memory.swapUsedBytes)))")
          .font(.caption)
        Chart {
          ForEach(Array(monitor.dashboard.memory.history.enumerated()), id: \.offset) { i, v in
            AreaMark(x: .value("t", i), y: .value("%", v))
          }
        }
        .frame(height: 80)
      }
    }
  }

  private var diskSection: some View {
    HubCard {
      VStack(alignment: .leading, spacing: 8) {
        LText("metric.disk").font(.headline)
        Text(String(format: "%.0f%%", monitor.dashboard.disk.usedPercent)).font(.title)
        Text(ByteCountFormat.string(monitor.dashboard.disk.freeBytes))
          .font(.caption)
      }
    }
  }

  private var temperatureSection: some View {
    HubCard {
      VStack(alignment: .leading, spacing: 8) {
        LText("metric.temperature").font(.headline)
        if let key = monitor.dashboard.temperature.unavailableReasonKey {
          Text(L10n.tr("temp.unavailable", locale: locale))
          Text(L10n.tr(key, locale: locale))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private var processesTable: some View {
    HubCard {
      VStack(alignment: .leading, spacing: 8) {
        LText("monitor.processes").font(.headline)
        Table(monitor.dashboard.topProcesses) {
          TableColumn(L10n.tr("monitor.column.process", locale: locale)) { row in Text(row.name) }
          TableColumn("CPU") { row in Text(String(format: "%.1f%%", row.cpuPercent)) }
          TableColumn("RAM") { row in Text(ByteCountFormat.string(row.memoryBytes)) }
        }
        .frame(minHeight: 220)
      }
    }
  }
}
