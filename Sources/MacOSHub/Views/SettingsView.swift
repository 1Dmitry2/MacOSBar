import HubPermissions
import HubSettings
import SwiftUI

struct SettingsView: View {
    @Bindable private var config = AppConfiguration.shared
    private let permissions = PermissionManager()

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $config.launchAtLogin)
                    .onChange(of: config.launchAtLogin) { _, on in LoginItemService.apply(enabled: on) }
                Toggle("Run in background when window closes", isOn: $config.runInBackground)
                Picker("Theme", selection: $config.theme) {
                    ForEach(AppTheme.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                Picker("Close window", selection: $config.closeWindowBehavior) {
                    ForEach(CloseWindowBehavior.allCases, id: \.self) {
                        Text($0 == .hideToBackground ? "Hide to background" : "Quit app").tag($0)
                    }
                }
            }
            Section("Modules") {
                ForEach(HubModuleID.allCases) { module in
                    Toggle(module.displayName, isOn: moduleBinding(module))
                }
            }
            Section("System Monitor") {
                Stepper("Update interval: \(Int(config.monitorUpdateInterval))s", value: $config.monitorUpdateInterval, in: 1...10)
                Toggle("Menu bar: CPU", isOn: $config.menuBarShowsCPU)
                Toggle("Menu bar: RAM", isOn: $config.menuBarShowsRAM)
            }
            Section("Device Control") {
                Stepper("Auto-unlock timer: \(config.deviceAutoUnlockSeconds)s", value: $config.deviceAutoUnlockSeconds, in: 60...3600, step: 60)
            }
            Section("Permissions") {
                ForEach(PermissionKind.allCases) { kind in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(kind.title)
                            Text(kind.purpose).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(permissions.status(for: kind).rawValue.capitalized)
                            .foregroundStyle(.secondary)
                        Button("Open") { permissions.openSettings(for: kind) }
                    }
                }
            }
            Section("About") {
                Text("MacOS Hub 1.0.0")
                Text(MacSummary.current().osVersion)
            }
        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("Settings")
    }

    private func moduleBinding(_ module: HubModuleID) -> Binding<Bool> {
        Binding(
            get: { config.isModuleEnabled(module) },
            set: { config.setModuleEnabled(module, enabled: $0) }
        )
    }
}

import HubCore
