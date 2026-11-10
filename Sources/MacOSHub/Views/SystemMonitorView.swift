import Charts
import HubCore
import HubSettings
import HubSystemMonitor
import SwiftUI

private enum ProcessSort: String, CaseIterable {
    case cpu
    case memory
    case name
}

struct SystemMonitorView: View {
    @Bindable private var monitor = SystemMonitorService.shared
    @Environment(\.locale) private var locale
    @State private var processes: [ProcessUsage] = []
    @State private var search = ""
    @State private var sort: ProcessSort = .cpu
    @State private var selection: Int32?
    @State private var refreshTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                cpuSection
                memorySection
                diskSection
                temperatureSection
                processesTable
                if let pid = selection, let selected = processes.first(where: { $0.id == pid }) {
                    processDetail(selected)
                }
            }
            .padding(24)
        }
        .onAppear {
            monitor.updateInterval = AppConfiguration.shared.monitorUpdateInterval
            if !monitor.isRunning { monitor.start() }
            reloadProcesses()
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                Task { @MainActor in reloadProcesses() }
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }

    private func reloadProcesses() {
        processes = monitor.readTopProcesses(limit: 60)
    }

    private var filteredProcesses: [ProcessUsage] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        var rows = processes
        if !query.isEmpty {
            rows = rows.filter {
                $0.name.localizedCaseInsensitiveContains(query)
                    || String($0.id).contains(query)
                    || ($0.bundleIdentifier?.localizedCaseInsensitiveContains(query) ?? false)
            }
        }
        switch sort {
        case .cpu:
            rows.sort { $0.cpuPercent == $1.cpuPercent ? $0.memoryBytes > $1.memoryBytes : $0.cpuPercent > $1.cpuPercent }
        case .memory:
            rows.sort { $0.memoryBytes == $1.memoryBytes ? $0.cpuPercent > $1.cpuPercent : $0.memoryBytes > $1.memoryBytes }
        case .name:
            rows.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        return rows
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
                if let celsius = monitor.dashboard.temperature.cpuCelsius {
                    Text(String(format: "%.0f°", celsius))
                } else if let key = monitor.dashboard.temperature.unavailableReasonKey {
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
                HStack {
                    TextField(L10n.tr("monitor.search", locale: locale), text: $search)
                        .textFieldStyle(.roundedBorder)
                    Picker("", selection: $sort) {
                        Text("CPU").tag(ProcessSort.cpu)
                        Text("RAM").tag(ProcessSort.memory)
                        Text(L10n.tr("monitor.column.process", locale: locale)).tag(ProcessSort.name)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 260)
                }
                Table(filteredProcesses, selection: $selection) {
                    TableColumn(L10n.tr("monitor.column.process", locale: locale)) { row in
                        Text(row.name)
                            .lineLimit(2)
                            .help(row.name)
                    }
                    .width(min: 180, ideal: 280)
                    TableColumn("CPU") { row in
                        Text(String(format: "%.1f%%", row.cpuPercent))
                            .monospacedDigit()
                    }
                    .width(70)
                    TableColumn("RAM") { row in
                        Text(ByteCountFormat.string(row.memoryBytes))
                            .monospacedDigit()
                    }
                    .width(90)
                    TableColumn("PID") { row in
                        Text(String(row.id))
                            .monospacedDigit()
                    }
                    .width(60)
                }
                .tableStyle(.inset(alternatesRowBackgrounds: true))
                .frame(minHeight: 280)
            }
        }
    }

    private func processDetail(_ process: ProcessUsage) -> some View {
        HubCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(process.name).font(.headline)
                LabeledContent("PID", value: String(process.id))
                LabeledContent("CPU", value: String(format: "%.1f%%", process.cpuPercent))
                LabeledContent("RAM", value: ByteCountFormat.string(process.memoryBytes))
                if let bundle = process.bundleIdentifier {
                    LabeledContent("Bundle ID", value: bundle)
                }
                if let path = process.executablePath {
                    LabeledContent(L10n.tr("monitor.path", locale: locale), value: path)
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
