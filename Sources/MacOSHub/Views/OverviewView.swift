import HubCleaner
import HubCore
import HubDeviceControl
import HubDynamicIsland
import HubSettings
import HubSystemMonitor
import SwiftUI

struct OverviewView: View {
  var navigate: (HubDestination) -> Void = { _ in }
  @Bindable private var monitor = SystemMonitorService.shared
  @Bindable private var config = AppConfiguration.shared
  @State private var summary = MacSummary.current()
  @Environment(\.locale) private var locale

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        header
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
          cpuCard
          memoryCard
          diskCard
          temperatureCard
        }
        modulesSection
      }
      .padding(24)
    }
    .onAppear { summary = MacSummary.current() }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(summary.modelName).font(.largeTitle.bold())
      Text("\(summary.osVersionString) (\(summary.osMarketingName))")
        .foregroundStyle(.secondary)
      Text("\(summary.chipName) · \(ByteCountFormat.string(Int64(summary.physicalMemoryBytes)))")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      Text(summary.deviceName)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private var cpuCard: some View {
    metricCard(titleKey: "metric.cpu", value: String(format: "%.1f%%", monitor.dashboard.cpu.totalUsage), subtitle: "\(monitor.dashboard.cpu.coreCount) \(L10n.tr("overview.cores", locale: locale))") {
      Sparkline(values: monitor.dashboard.cpu.history)
    }
  }

  private var memoryCard: some View {
    metricCard(titleKey: "metric.memory", value: ByteCountFormat.string(Int64(monitor.dashboard.memory.usedBytes)), subtitle: "\(ByteCountFormat.string(Int64(monitor.dashboard.memory.totalBytes))) · \(monitor.dashboard.memory.pressure)") {
      ProgressView(value: monitor.dashboard.memory.usedFraction)
    }
  }

  private var diskCard: some View {
    metricCard(titleKey: "metric.disk", value: String(format: "%.0f%%", monitor.dashboard.disk.usedPercent), subtitle: monitor.dashboard.disk.volumeName) {
      ProgressView(value: monitor.dashboard.disk.usedPercent / 100)
    }
  }

  private var temperatureCard: some View {
    metricCard(
      titleKey: "metric.temperature",
      value: monitor.dashboard.temperature.isAvailable ? String(format: "%.0f°", monitor.dashboard.temperature.cpuCelsius ?? 0) : L10n.tr("temp.unavailable", locale: locale),
      subtitle: temperatureSubtitle
    ) { EmptyView() }
  }

  private var temperatureSubtitle: String {
    guard let key = monitor.dashboard.temperature.unavailableReasonKey else { return "" }
    return L10n.tr(key, locale: locale)
  }

  private func metricCard<Content: View>(titleKey: String, value: String, subtitle: String, @ViewBuilder chart: () -> Content) -> some View {
    HubCard {
      VStack(alignment: .leading, spacing: 10) {
        LText(titleKey).font(.headline)
        Text(value).font(.title2.bold())
        Text(subtitle).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        chart()
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var modulesSection: some View {
    HubCard {
      VStack(alignment: .leading, spacing: 12) {
        LText("overview.modules").font(.headline)
        ForEach(moduleRows) { row in
          HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
              Text(L10n.tr(row.id.localizationKey, locale: locale))
              Text(L10n.tr(row.isActive ? "status.active" : "status.inactive", locale: locale))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle(isOn: moduleToggle(row.id)) { EmptyView() }
              .toggleStyle(.switch)
              .labelsHidden()
            if let dest = row.destination {
              Button(L10n.tr("overview.open", locale: locale)) { navigate(dest) }
            }
          }
        }
        HStack {
          LText("overview.uptime")
          Spacer()
          Text(formatUptime(monitor.dashboard.uptime)).foregroundStyle(.secondary)
        }
      }
    }
  }

  private var moduleRows: [ModuleRuntimeRow] {
    ModuleRuntimeRow.overviewRows(
      config: config,
      monitorRunning: monitor.isRunning,
      islandRunning: DynamicIslandController.shared.isRunning,
      deviceLockActive: InputLockService.shared.keyboardLocked || InputLockService.shared.trackpadLocked
    )
  }

  private func moduleToggle(_ id: HubModuleID) -> Binding<Bool> {
    Binding(
      get: {
        switch id {
        case .dynamicIsland: return config.dynamicIslandEnabled
        default: return config.isModuleEnabled(id)
        }
      },
      set: { on in
        switch id {
        case .dynamicIsland:
          config.dynamicIslandEnabled = on
          Task { @MainActor in
            if on { DynamicIslandController.shared.startIfEnabled() }
            else { DynamicIslandController.shared.stop() }
          }
        default:
          config.setModuleEnabled(id, enabled: on)
        }
      }
    )
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
