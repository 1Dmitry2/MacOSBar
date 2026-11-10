import HubCore
import HubDynamicIsland
import HubSettings
import SwiftUI

struct DynamicIslandSettingsView: View {
  @Bindable private var config = AppConfiguration.shared
  @State private var running = DynamicIslandController.shared.isRunning

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        islandPreview
        controls
        widgetSection
      }
      .padding(24)
    }
    .onAppear { running = DynamicIslandController.shared.isRunning }
  }

  private var islandPreview: some View {
    HubCard {
      VStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(.black.opacity(0.9))
          .frame(height: running ? 88 : 40)
          .overlay {
            HStack {
              Text(Date(), style: .time)
              Spacer()
              Text(running ? LocalizedStringKey("status.active") : LocalizedStringKey("status.inactive"))
                .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 24)
          }
        Text("Превью панели у выреза MacBook")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var controls: some View {
    HubCard {
      VStack(alignment: .leading, spacing: 12) {
        Toggle(isOn: $config.dynamicIslandEnabled) {
          Text(LocalizedStringKey("island.enable"))
        }
        .onChange(of: config.dynamicIslandEnabled) { _, on in
          Task { @MainActor in
            if on { DynamicIslandController.shared.startIfEnabled() }
            else { DynamicIslandController.shared.stop() }
            running = DynamicIslandController.shared.isRunning
          }
        }

        HStack {
          Button(String(localized: "island.start", bundle: .module)) {
            config.dynamicIslandEnabled = true
            Task { @MainActor in
              DynamicIslandController.shared.startIfEnabled()
              running = DynamicIslandController.shared.isRunning
            }
          }
          Button(String(localized: "island.stop", bundle: .module)) {
            Task { @MainActor in
              DynamicIslandController.shared.stop()
              running = false
            }
          }
        }

        Toggle("Автозапуск вместе с приложением", isOn: $config.dynamicIslandAutostart)
        Text(running ? "Панель отображается на рабочем столе." : "Панель остановлена.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var widgetSection: some View {
    HubCard {
      VStack(alignment: .leading, spacing: 8) {
        Text("Виджеты").font(.headline)
        Text("Часы · Батарея · CPU · RAM")
        Text("Нажатие по панели — расширенный режим.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}
