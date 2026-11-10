import AppKit
import HubCore
import HubDeviceControl
import HubDynamicIsland
import HubSettings
import HubSystemMonitor
import SwiftUI

@main
struct MacOSHubApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Bindable private var navigation = NavigationState.shared
    @Bindable private var config = AppConfiguration.shared
    @Bindable private var monitor = SystemMonitorService.shared

    var body: some Scene {
        WindowGroup {
            ContentView(selection: $navigation.selection)
                .frame(minWidth: 1080, minHeight: 720)
                .preferredColorScheme(colorScheme)
                .environment(\.locale, config.language.locale)
                .id(config.language)
        }

        MenuBarExtra {
            MenuBarMonitorPopover {
                openMainWindow(to: .systemMonitor)
            }
            Divider()
            Button(L10n.tr("menubar.open", locale: config.language.locale)) { openMainWindow() }
            Button(L10n.tr("nav.overview", locale: config.language.locale)) { openMainWindow(to: .overview) }
            Button(L10n.tr("nav.smartCleaner", locale: config.language.locale)) { openMainWindow(to: .smartCleaner) }
            Button(L10n.tr("nav.systemMonitor", locale: config.language.locale)) { openMainWindow(to: .systemMonitor) }
            Divider()
            Button(L10n.tr("menubar.quit", locale: config.language.locale)) { NSApplication.shared.terminate(nil) }
        } label: {
            HStack(spacing: 6) {
                if config.menuBarShowsCPU {
                    Text("CPU \(String(format: "%.0f%%", monitor.dashboard.cpu.totalUsage))")
                }
                if config.menuBarShowsRAM {
                    Text("RAM \(String(format: "%.0f%%", monitor.dashboard.memory.usedFraction * 100))")
                }
                if config.menuBarShowsDisk {
                    Text("SSD \(String(format: "%.0f%%", monitor.dashboard.disk.usedPercent))")
                }
                if config.menuBarShowsTemperature, let c = monitor.dashboard.temperature.cpuCelsius {
                    Text(String(format: "%.0f°", c))
                }
            }
            .font(.caption.monospacedDigit())
        }
        .menuBarExtraStyle(.window)
    }

    private var colorScheme: ColorScheme? {
        switch config.theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private func openMainWindow(to destination: HubDestination? = nil) {
        if let destination { navigation.selection = destination }
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.canBecomeMain {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
