import HubCore
import SwiftUI

struct ContentView: View {
    @Binding var selection: HubDestination

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            DetailRouter(selection: selection)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

struct SidebarView: View {
    @Binding var selection: HubDestination

    var body: some View {
        List(HubDestination.allCases, selection: $selection) { dest in
            Label(dest.title, systemImage: dest.systemImage)
        }
        .listStyle(.sidebar)
        .navigationTitle("MacOS Hub")
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("v1.0.0")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }
}

struct DetailRouter: View {
    let selection: HubDestination

    var body: some View {
        Group {
            switch selection {
            case .overview: OverviewView()
            case .smartCleaner: CleanerView()
            case .systemMonitor: SystemMonitorView()
            case .deviceControl: DeviceControlView()
            case .dynamicIsland: DynamicIslandSettingsView()
            case .settings: SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
