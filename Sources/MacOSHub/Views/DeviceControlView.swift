import HubDeviceControl
import HubCore
import SwiftUI

struct DeviceControlView: View {
    @Bindable private var service = InputLockService.shared
    @State private var confirmLock = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Device Control")
                .font(.largeTitle.bold())
            Text(service.limitationNotice)
                .font(.callout)
                .foregroundStyle(.secondary)
            HubCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Cleanup Settings").font(.headline)
                    Toggle("Lock Keyboard", isOn: $service.keyboardLocked)
                        .onChange(of: service.keyboardLocked) { _, on in
                            if on { confirmLock = true; service.setKeyboardLock(true) }
                            else { service.setKeyboardLock(false) }
                        }
                    Toggle("Lock Trackpad", isOn: $service.trackpadLocked)
                        .onChange(of: service.trackpadLocked) { _, on in
                            if on { confirmLock = true; service.setTrackpadLock(true) }
                            else { service.setTrackpadLock(false) }
                        }
                    if case .active(let mode, let exp) = service.state {
                        Label("Active: \(mode == .keyboard ? "Keyboard" : "Trackpad")", systemImage: "lock.fill")
                            .foregroundStyle(HubTheme.cautionYellow)
                        if let exp {
                            Text("Auto-unlock at \(exp.formatted(date: .omitted, time: .standard))")
                                .font(.caption)
                        }
                    }
                    if case .permissionRequired = service.state {
                        Button("Grant Permissions") { service.requestPermissions() }
                    }
                    Button("Unlock Now", role: .destructive) { service.unlockAll() }
                }
            }
            Text("Emergency: hold both Command keys for ~3 seconds to unlock input.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(24)
        .navigationTitle("Device Control")
        .alert("Enable input lock?", isPresented: $confirmLock) {
            Button("Cancel", role: .cancel) {
                service.unlockAll()
            }
            Button("Lock") { }
        } message: {
            Text("Confirm you can unlock via the button above or Command+Command hold.")
        }
    }
}
