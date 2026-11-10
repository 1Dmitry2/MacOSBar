import HubDeviceControl
import HubCore
import SwiftUI

struct DeviceControlView: View {
  @Bindable private var service = InputLockService.shared
  @State private var confirmLock: InputLockMode?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text(LocalizedStringKey("device.title")).font(.largeTitle.bold())
        Text(LocalizedStringKey("device.subtitle"))
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
        Text(service.limitationNotice)
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(12)
          .background(HubTheme.cardBackground)
          .clipShape(RoundedRectangle(cornerRadius: 10))

        inputCard(
          icon: "keyboard",
          titleKey: "device.keyboard.lock",
          detail: "Трекпад остаётся доступным.",
          locked: service.keyboardLocked
        ) {
          if service.keyboardLocked { service.unlockAll() }
          else { confirmLock = .keyboard }
        }

        inputCard(
          icon: "hand.point.up.left",
          titleKey: "device.trackpad.lock",
          detail: "Клавиатура остаётся доступной.",
          locked: service.trackpadLocked
        ) {
          if service.trackpadLocked { service.unlockAll() }
          else { confirmLock = .trackpad }
        }

        if case .permissionRequired = service.state {
          Button("Выдать разрешения") { service.requestPermissions() }
        }

        Text("Аварийная разблокировка: удерживайте обе клавиши Command ~3 с.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(24)
    }
    .alert(item: $confirmLock) { mode in
      Alert(
        title: Text(mode == .keyboard ? LocalizedStringKey("device.keyboard.lock") : LocalizedStringKey("device.trackpad.lock")),
        message: Text("Подтвердите блокировку. Разблокировка — кнопкой или Command+Command."),
        primaryButton: .destructive(Text(LocalizedStringKey("action.confirm"))) {
          if mode == .keyboard { service.setKeyboardLock(true) }
          else { service.setTrackpadLock(true) }
        },
        secondaryButton: .cancel(Text(LocalizedStringKey("action.cancel")))
      )
    }
  }

  private func inputCard(icon: String, titleKey: String, detail: String, locked: Bool, action: @escaping () -> Void) -> some View {
    HubCard {
      HStack(spacing: 16) {
        Image(systemName: icon).font(.largeTitle)
        VStack(alignment: .leading, spacing: 6) {
          Text(LocalizedStringKey(titleKey)).font(.headline)
          Text(detail).font(.caption).foregroundStyle(.secondary)
          Text(locked ? LocalizedStringKey("status.active") : LocalizedStringKey("status.inactive"))
            .font(.caption.bold())
            .foregroundStyle(locked ? HubTheme.cautionYellow : HubTheme.successGreen)
        }
        Spacer()
        Button(locked ? String(localized: "device.unlock", bundle: .module) : String(localized: String.LocalizationValue(titleKey), bundle: .module), action: action)
          .buttonStyle(.borderedProminent)
          .tint(locked ? .red : HubTheme.accentPurple)
      }
    }
  }
}
