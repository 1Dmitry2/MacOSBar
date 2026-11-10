import AppKit
import HubCore
import HubDiagnostics
import HubDynamicIsland
import HubPermissions
import HubSystemMonitor
import SwiftUI

struct DiagnosticsView: View {
  @Bindable private var store = DiagnosticsStore.shared
  @Bindable private var monitor = SystemMonitorService.shared
  private let permissions = PermissionManager()
  private let summary = MacSummary.current()

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      statusGrid
      List(store.entries) { entry in
        VStack(alignment: .leading, spacing: 2) {
          Text("[\(entry.level)] \(entry.category)")
            .font(.caption.bold())
          Text(entry.message).font(.caption)
          Text(entry.date.formatted()).font(.caption2).foregroundStyle(.secondary)
        }
      }
      HStack {
        Button(String(localized: "diag.export", bundle: .module)) { exportReport() }
        Button(String(localized: "diag.clear", bundle: .module)) { store.clear() }
      }
    }
    .padding(24)
    .onAppear { refreshSnapshot() }
  }

  private var statusGrid: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
      statusCard("Мониторинг", monitor.isRunning ? "Работает" : "Остановлен")
      statusCard("Dynamic Island", DynamicIslandController.shared.isRunning ? "Работает" : "Остановлен")
      statusCard("Accessibility", permissions.status(for: .accessibility).rawValue)
      statusCard("Input Monitoring", permissions.status(for: .inputMonitoring).rawValue)
    }
  }

  private func statusCard(_ title: String, _ value: String) -> some View {
    HubCard {
      VStack(alignment: .leading) {
        Text(title).font(.headline)
        Text(value).foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func refreshSnapshot() {
    store.log(level: "INFO", category: .app, message: "Diagnostics opened · \(summary.modelName) · \(summary.osVersionString)")
  }

  private func exportReport() {
    let text = store.exportReport(macSummary: "\(summary.modelName) · \(summary.osVersionString) · \(summary.architecture)")
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
    let save = NSSavePanel()
    save.nameFieldStringValue = "macoshub-diagnostics.txt"
    if save.runModal() == .OK, let url = save.url {
      try? text.write(to: url, atomically: true, encoding: .utf8)
    }
  }
}
