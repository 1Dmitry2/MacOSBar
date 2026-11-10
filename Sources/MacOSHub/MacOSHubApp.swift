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
        }
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Quit MacOS Hub") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q", modifiers: .command)
            }
        }

        MenuBarExtra("MacOS Hub", systemImage: "gauge.with.dots.needle.67percent") {
            if config.menuBarShowsCPU {
                Text("CPU \(String(format: "%.0f%%", monitor.dashboard.cpu.totalUsage))")
            }
            if config.menuBarShowsRAM {
                Text("RAM \(String(format: "%.0f%%", monitor.dashboard.memory.usedFraction * 100))")
            }
            Divider()
            Button("Open MacOS Hub") { openMainWindow() }
            Button("Overview") { openMainWindow(to: .overview) }
            Button("Smart Cleaner") { openMainWindow(to: .smartCleaner) }
            Button("System Monitor") { openMainWindow(to: .systemMonitor) }
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
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
