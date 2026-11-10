import HubCore
import HubDeviceControl
import SwiftUI

struct DeviceControlView: View {
  @Bindable private var service = InputLockService.shared
  @State private var confirmLock: InputLockMode?
  @Environment(\.locale) private var locale

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        LText("device.title").font(.largeTitle.bold())
        LText("device.subtitle").foregroundStyle(.secondary)
        Text(L10n.tr("device.limitation", locale: locale))
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(12)
          .background(HubTheme.cardBackground)
          .clipShape(RoundedRectangle(cornerRadius: 10))

        inputCard(icon: "keyboard", titleKey: "device.keyboard.lock", detailKey: "device.keyboard.detail", locked: service.keyboardLocked) {
          if service.keyboardLocked { service.unlockAll() }
          else { confirmLock = .keyboard }
        }

        inputCard(icon: "hand.point.up.left", titleKey: "device.trackpad.lock", detailKey: "device.trackpad.detail", locked: service.trackpadLocked) {
          if service.trackpadLocked { service.unlockAll() }
          else { confirmLock = .trackpad }
        }

        if case .permissionRequired = service.state {
          Button(L10n.tr("device.permissions", locale: locale)) { service.requestPermissions() }
        }

        Text(L10n.tr("device.emergency", locale: locale))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(24)
    }
    .confirmationDialog(
      L10n.tr(confirmLock == .keyboard ? "device.keyboard.lock" : "device.trackpad.lock", locale: locale),
      isPresented: Binding(
        get: { confirmLock != nil },
        set: { if !$0 { confirmLock = nil } }
      ),
      titleVisibility: .visible
    ) {
      Button(L10n.tr("action.confirm", locale: locale), role: .destructive) {
        if confirmLock == .keyboard { service.setKeyboardLock(true) }
        else if confirmLock == .trackpad { service.setTrackpadLock(true) }
        confirmLock = nil
      }
      Button(L10n.tr("action.cancel", locale: locale), role: .cancel) { confirmLock = nil }
    } message: {
      Text(L10n.tr("device.lock.confirm.message", locale: locale))
    }
  }

  private func inputCard(icon: String, titleKey: String, detailKey: String, locked: Bool, action: @escaping () -> Void) -> some View {
    HubCard {
      HStack(spacing: 16) {
        Image(systemName: icon).font(.largeTitle)
        VStack(alignment: .leading, spacing: 6) {
          LText(titleKey).font(.headline)
          Text(L10n.tr(detailKey, locale: locale)).font(.caption).foregroundStyle(.secondary)
          Text(L10n.tr(locked ? "status.active" : "status.inactive", locale: locale))
            .font(.caption.bold())
        }
        Spacer()
        Button(locked ? L10n.tr("device.unlock", locale: locale) : L10n.tr(titleKey, locale: locale), action: action)
          .buttonStyle(.borderedProminent)
          .tint(locked ? .red : HubTheme.accentPurple)
      }
    }
  }
}
