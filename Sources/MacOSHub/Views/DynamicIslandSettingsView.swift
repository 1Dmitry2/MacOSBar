import HubDynamicIsland
import HubSettings
import SwiftUI

struct DynamicIslandSettingsView: View {
    @Bindable private var config = AppConfiguration.shared

    var body: some View {
        Form {
            Toggle("Enable Dynamic Island", isOn: $config.dynamicIslandEnabled)
                .onChange(of: config.dynamicIslandEnabled) { _, on in
                    Task { @MainActor in
                        if on { DynamicIslandController.shared.startIfEnabled() }
                        else { DynamicIslandController.shared.stop() }
                    }
                }
            Text("Floating panel near the notch (or top center on displays without a notch). Works when the main window is closed.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Section("Widgets") {
                Text("Time, CPU, RAM, and battery (compact). Tap to expand.")
            }
        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("Dynamic Island")
    }
}
