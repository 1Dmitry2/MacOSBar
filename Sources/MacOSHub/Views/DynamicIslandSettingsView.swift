import CoreGraphics
import HubCore
import HubDynamicIsland
import HubSettings
import SwiftUI

struct DynamicIslandSettingsView: View {
    @Bindable private var config = AppConfiguration.shared
    @State private var running = DynamicIslandController.shared.isRunning
    @Environment(\.locale) private var locale
    private let screens = HubDisplayResolver.availableScreens()

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
                            .onChange(of: config.dynamicIslandEnabled) { _, _ in
                                DynamicIslandController.shared.applySettingsChange()
                                running = DynamicIslandController.shared.isRunning
                            }

                        Picker(L10n.tr("island.display", locale: locale), selection: $config.islandDisplayMode) {
                            Text(L10n.tr("island.display.builtIn", locale: locale)).tag(IslandDisplayMode.builtIn)
                            Text(L10n.tr("island.display.main", locale: locale)).tag(IslandDisplayMode.mainDisplay)
                            Text(L10n.tr("island.display.specific", locale: locale)).tag(IslandDisplayMode.specific)
                        }
                        .onChange(of: config.islandDisplayMode) { _, _ in
                            DynamicIslandController.shared.applySettingsChange()
                        }

                        if config.islandDisplayMode == .specific {
                            Picker(L10n.tr("island.display.pick", locale: locale), selection: displayIDBinding) {
                                ForEach(screens, id: \.id) { screen in
                                    Text(screenTitle(screen)).tag(Optional(screen.id))
                                }
                            }
                            .onChange(of: config.islandDisplayID) { _, _ in
                                DynamicIslandController.shared.applySettingsChange()
                            }
                        }

                        Slider(
                            value: $config.islandVerticalOffset,
                            in: -20...20,
                            step: 1
                        ) {
                            Text(L10n.tr("island.verticalOffset", locale: locale))
                        }
                        .onChange(of: config.islandVerticalOffset) { _, _ in
                            DynamicIslandController.shared.reposition(animated: true)
                        }

                        widgetToggles

                        HStack {
                            Button(L10n.tr("island.start", locale: locale)) {
                                config.dynamicIslandEnabled = true
                                DynamicIslandController.shared.startIfEnabled()
                                running = DynamicIslandController.shared.isRunning
                            }
                            Button(L10n.tr("island.stop", locale: locale)) {
                                DynamicIslandController.shared.stop()
                                running = false
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .onAppear { running = DynamicIslandController.shared.isRunning }
    }

    private var widgetToggles: some View {
        VStack(alignment: .leading, spacing: 8) {
            LText("island.widgets").font(.headline)
            Toggle("CPU", isOn: $config.islandWidgetShowsCPU)
            Toggle("RAM", isOn: $config.islandWidgetShowsRAM)
            Toggle("Disk", isOn: $config.islandWidgetShowsDisk)
            Toggle("Battery", isOn: $config.islandWidgetShowsBattery)
            Toggle("Time", isOn: $config.islandWidgetShowsTime)
            Toggle("Date", isOn: $config.islandWidgetShowsDate)
            Toggle("Network", isOn: $config.islandWidgetShowsNetwork)
        }
    }

    private var displayIDBinding: Binding<CGDirectDisplayID?> {
        Binding(
            get: { config.islandDisplayID },
            set: { config.islandDisplayID = $0 }
        )
    }

    private func screenTitle(_ screen: (id: CGDirectDisplayID, name: String, builtIn: Bool)) -> String {
        if screen.builtIn {
            return "\(screen.name) · \(L10n.tr("island.display.builtIn", locale: locale))"
        }
        return screen.name
    }
}
