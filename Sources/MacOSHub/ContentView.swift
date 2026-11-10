import HubCore
import HubSettings
import SwiftUI

struct ContentView: View {
    @Binding var selection: HubDestination
    @Bindable private var config = AppConfiguration.shared

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        } detail: {
            NavigationStack {
                DetailRouter(selection: selection, navigate: { selection = $0 })
                    .navigationTitle(Text(LocalizedStringKey(selection.localizationKey)))
                    .id(selection)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
            .animation(.easeInOut(duration: 0.2), value: selection)
        }
        .environment(\.locale, config.language.locale)
    }
}

struct SidebarView: View {
    @Binding var selection: HubDestination

    var body: some View {
        List {
            ForEach(HubDestination.allCases) { dest in
                SidebarRow(dest: dest, isSelected: selection == dest)
                    .contentShape(Rectangle())
                    .onTapGesture { selection = dest }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(selection == dest ? HubTheme.sidebarSelection.opacity(0.35) : Color.clear)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                    )
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("MacOS Hub")
        .safeAreaInset(edge: .bottom) {
            Text("v1.1.0")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
        }
    }
}

private struct SidebarRow: View {
    let dest: HubDestination
    let isSelected: Bool

    var body: some View {
        Label {
            Text(LocalizedStringKey(dest.localizationKey))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        } icon: {
            Image(systemName: dest.systemImage)
        }
        .labelStyle(.titleAndIcon)
        .foregroundStyle(isSelected ? .primary : .secondary)
    }
}

struct DetailRouter: View {
    let selection: HubDestination
    var navigate: (HubDestination) -> Void = { _ in }

    var body: some View {
        Group {
            switch selection {
            case .overview:
                OverviewView(navigate: navigate)
            case .smartCleaner:
                CleanerView()
            case .systemMonitor:
                SystemMonitorView()
            case .deviceControl:
                DeviceControlView()
            case .dynamicIsland:
                DynamicIslandSettingsView()
            case .diagnostics:
                DiagnosticsView()
            case .settings:
                SettingsView()
            }
        }
        .padding(.bottom, 4)
    }
}
