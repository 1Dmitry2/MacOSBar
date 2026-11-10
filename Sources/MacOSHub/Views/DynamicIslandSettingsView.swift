import HubCore
import HubDynamicIsland
import HubSettings
import SwiftUI

struct DynamicIslandSettingsView: View {
  @Bindable private var config = AppConfiguration.shared
  @State private var running = DynamicIslandController.shared.isRunning
  @Environment(\.locale) private var locale

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        HubCard {
          RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.black.opacity(0.9))
            .frame(height: running ? 88 : 40)
            .overlay {
              Text(running ? L10n.tr("status.active", locale: locale) : L10n.tr("status.inactive", locale: locale))
                .foregroundStyle(.white)
            }
        }
        HubCard {
          VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $config.dynamicIslandEnabled) { LText("island.enable") }
            HStack {
              Button(L10n.tr("island.start", locale: locale)) {
                config.dynamicIslandEnabled = true
                Task { @MainActor in
                  DynamicIslandController.shared.startIfEnabled()
                  running = DynamicIslandController.shared.isRunning
                }
              }
              Button(L10n.tr("island.stop", locale: locale)) {
                Task { @MainActor in
                  DynamicIslandController.shared.stop()
                  running = false
                }
              }
            }
          }
        }
      }
      .padding(24)
    }
    .onAppear { running = DynamicIslandController.shared.isRunning }
  }
}
