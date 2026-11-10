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
  @Environment(\.locale) private var locale
  private let permissions = PermissionManager()
  @State private var summary = MacSummary.current()

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      statusGrid
      List(store.entries) { entry in
        VStack(alignment: .leading, spacing: 2) {
          Text(entry.message).font(.caption)
          Text(entry.date.formatted()).font(.caption2).foregroundStyle(.secondary)
        }
      }
      HStack {
        Button(L10n.tr("diag.export", locale: locale)) { exportReport() }
        Button(L10n.tr("diag.clear", locale: locale)) { store.clear() }
      }
    }
    .padding(24)
    .onAppear {
      summary = MacSummary.current()
      store.log(level: "INFO", category: .app, message: "Diagnostics open")
    }
  }

  private var statusGrid: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
      statusCard(L10n.tr("module.systemMonitor", locale: locale), monitor.isRunning ? L10n.tr("status.active", locale: locale) : L10n.tr("status.inactive", locale: locale))
      statusCard("Dynamic Island", DynamicIslandController.shared.isRunning ? L10n.tr("status.active", locale: locale) : L10n.tr("status.inactive", locale: locale))
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

  private func exportReport() {
    let text = store.exportReport(macSummary: "\(summary.modelName) · \(summary.osVersionString)")
    let save = NSSavePanel()
    save.nameFieldStringValue = "macoshub-diagnostics.txt"
    if save.runModal() == .OK, let url = save.url {
      try? text.write(to: url, atomically: true, encoding: .utf8)
    }
  }
}
