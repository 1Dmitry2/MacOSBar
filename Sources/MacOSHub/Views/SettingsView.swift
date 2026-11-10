import HubCore
import HubPermissions
import HubSettings
import HubShortcuts
import HubSystemMonitor
import SwiftUI

struct SettingsView: View {
  @Bindable private var config = AppConfiguration.shared
  private let permissions = PermissionManager()
  @State private var summary = MacSummary.current()
  @Environment(\.locale) private var locale

  var body: some View {
    Form {
      Section {
        Picker(L10n.tr("settings.language", locale: locale), selection: $config.language) {
          ForEach(AppLanguage.allCases, id: \.self) { lang in
            Text(lang.displayName).tag(lang)
          }
        }
        Toggle(L10n.tr("settings.launchAtLogin", locale: locale), isOn: $config.launchAtLogin)
          .onChange(of: config.launchAtLogin) { _, on in LoginItemService.apply(enabled: on) }
        Toggle(L10n.tr("settings.background", locale: locale), isOn: $config.runInBackground)
        Picker(L10n.tr("settings.theme", locale: locale), selection: $config.theme) {
          Text(L10n.tr("settings.theme.system", locale: locale)).tag(AppTheme.system)
          Text(L10n.tr("settings.theme.light", locale: locale)).tag(AppTheme.light)
          Text(L10n.tr("settings.theme.dark", locale: locale)).tag(AppTheme.dark)
        }
        Picker(L10n.tr("settings.closeWindow", locale: locale), selection: $config.closeWindowBehavior) {
          Text(L10n.tr("settings.close.hide", locale: locale)).tag(CloseWindowBehavior.hideToBackground)
          Text(L10n.tr("settings.close.quit", locale: locale)).tag(CloseWindowBehavior.quit)
        }
      } header: { LText("settings.general") }

      Section {
        ForEach(HubModuleID.allCases) { module in
          Toggle(L10n.tr(module.localizationKey, locale: locale), isOn: moduleBinding(module))
        }
      } header: { LText("settings.modules") }

      Section {
        Stepper("Интервал: \(Int(config.monitorUpdateInterval)) с", value: $config.monitorUpdateInterval, in: 1...10)
          .onChange(of: config.monitorUpdateInterval) { _, v in
            SystemMonitorService.shared.updateInterval = v
          }
        Toggle(L10n.tr("menubar.cpu", locale: locale), isOn: $config.menuBarShowsCPU)
        Toggle(L10n.tr("menubar.ram", locale: locale), isOn: $config.menuBarShowsRAM)
        Toggle(L10n.tr("menubar.disk", locale: locale), isOn: $config.menuBarShowsDisk)
        Toggle(L10n.tr("menubar.temp", locale: locale), isOn: $config.menuBarShowsTemperature)
        Toggle(L10n.tr("sidebar.monitor.enable", locale: locale), isOn: $config.monitorSidebarEnabled)
            .onChange(of: config.monitorSidebarEnabled) { _, on in
                if on {
                    MonitorSidebarController.shared.show()
                } else {
                    MonitorSidebarController.shared.hide()
                }
            }
        Picker(L10n.tr("sidebar.monitor.edge", locale: locale), selection: $config.monitorSidebarEdge) {
            Text(L10n.tr("sidebar.edge.left", locale: locale)).tag(MonitorSidebarEdge.left)
            Text(L10n.tr("sidebar.edge.right", locale: locale)).tag(MonitorSidebarEdge.right)
        }
        .onChange(of: config.monitorSidebarEdge) { _, _ in
            MonitorSidebarController.shared.reposition()
        }
      } header: { LText("settings.monitor") }

      ShortcutsSettingsSection()

      Section {
        Toggle(L10n.tr("island.enable", locale: locale), isOn: $config.dynamicIslandEnabled)
        Toggle("Автозапуск", isOn: $config.dynamicIslandAutostart)
      } header: { Text("Dynamic Island") }

      Section {
        ForEach(PermissionKind.allCases) { kind in
          HStack {
            VStack(alignment: .leading) {
              Text(localizedPermissionTitle(kind))
              Text(kind.purpose).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Button("…") { permissions.openSettings(for: kind) }
          }
        }
      } header: { Text("Разрешения") }

      Section {
        Text("MacOS Hub 1.2.0")
        Text(summary.osVersionString)
        Text(summary.architecture)
      } header: { LText("settings.about") }
    }
    .formStyle(.grouped)
    .padding()
    .onAppear { summary = MacSummary.current() }
  }

  private func localizedPermissionTitle(_ kind: PermissionKind) -> String {
    switch kind {
    case .accessibility: return locale.identifier.hasPrefix("ru") ? "Универсальный доступ" : kind.title
    case .inputMonitoring: return locale.identifier.hasPrefix("ru") ? "Мониторинг ввода" : kind.title
    case .notifications: return locale.identifier.hasPrefix("ru") ? "Уведомления" : kind.title
    case .fullDiskAccess: return locale.identifier.hasPrefix("ru") ? "Полный доступ к диску" : kind.title
    }
  }

  private func moduleBinding(_ module: HubModuleID) -> Binding<Bool> {
    Binding(
      get: { config.isModuleEnabled(module) },
      set: { config.setModuleEnabled(module, enabled: $0) }
    )
  }
}
