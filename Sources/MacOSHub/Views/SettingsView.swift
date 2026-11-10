import HubCore
import HubPermissions
import HubSettings
import SwiftUI

struct SettingsView: View {
  @Bindable private var config = AppConfiguration.shared
  private let permissions = PermissionManager()
  private let summary = MacSummary.current()

  var body: some View {
    Form {
      Section {
        Picker(String(localized: "settings.language", bundle: .module), selection: $config.language) {
          ForEach(AppLanguage.allCases, id: \.self) { lang in
            Text(lang.displayName).tag(lang)
          }
        }
        Toggle("Запуск при входе", isOn: $config.launchAtLogin)
          .onChange(of: config.launchAtLogin) { _, on in LoginItemService.apply(enabled: on) }
        Toggle("Работа в фоне при закрытии окна", isOn: $config.runInBackground)
        Picker("Тема", selection: $config.theme) {
          Text("Системная").tag(AppTheme.system)
          Text("Светлая").tag(AppTheme.light)
          Text("Тёмная").tag(AppTheme.dark)
        }
        Picker("Закрытие окна", selection: $config.closeWindowBehavior) {
          Text("Скрыть в фон").tag(CloseWindowBehavior.hideToBackground)
          Text("Завершить приложение").tag(CloseWindowBehavior.quit)
        }
      } header: { Text(LocalizedStringKey("settings.general")) }

      Section("Модули") {
        ForEach(HubModuleID.allCases) { module in
          Toggle(LocalizedStringKey(module.localizationKey), isOn: moduleBinding(module))
        }
      }

      Section("Мониторинг") {
        Stepper("Интервал: \(Int(config.monitorUpdateInterval)) с", value: $config.monitorUpdateInterval, in: 1...10)
          .onChange(of: config.monitorUpdateInterval) { _, v in
            SystemMonitorService.shared.updateInterval = v
          }
        Toggle("Menu Bar: CPU", isOn: $config.menuBarShowsCPU)
        Toggle("Menu Bar: RAM", isOn: $config.menuBarShowsRAM)
      }

      Section("Устройства") {
        Stepper("Авторазблокировка: \(config.deviceAutoUnlockSeconds) с", value: $config.deviceAutoUnlockSeconds, in: 60...3600, step: 60)
      }

      Section("Dynamic Island") {
        Toggle(isOn: $config.dynamicIslandEnabled) { Text(LocalizedStringKey("island.enable")) }
        Toggle("Автозапуск", isOn: $config.dynamicIslandAutostart)
      }

      Section("Разрешения") {
        ForEach(PermissionKind.allCases) { kind in
          HStack {
            VStack(alignment: .leading) {
              Text(kind.title)
              Text(kind.purpose).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Text(permissions.status(for: kind).rawValue)
              .foregroundStyle(.secondary)
            Button("Открыть") { permissions.openSettings(for: kind) }
          }
        }
      }

      Section("О приложении") {
        Text("MacOS Hub 1.1.0")
        Text(summary.osVersionString)
        Text(summary.architecture)
      }
    }
    .formStyle(.grouped)
    .padding()
  }

  private func moduleBinding(_ module: HubModuleID) -> Binding<Bool> {
    Binding(
      get: { config.isModuleEnabled(module) },
      set: { config.setModuleEnabled(module, enabled: $0) }
    )
  }
}

import HubSystemMonitor
