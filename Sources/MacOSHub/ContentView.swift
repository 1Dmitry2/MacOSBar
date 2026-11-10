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
                    .navigationTitle(L10n.tr(selection.localizationKey, locale: config.language.locale))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .environment(\.locale, config.language.locale)
        .environment(\.localizationBundle, .module)
        .id(config.language)
    }
}

struct SidebarView: View {
    @Binding var selection: HubDestination
    @Environment(\.locale) private var locale

    var body: some View {
        List {
            ForEach(HubDestination.allCases) { dest in
                Button {
                    selection = dest
                } label: {
                    SidebarRow(dest: dest, isSelected: selection == dest, locale: locale)
                }
                .buttonStyle(.plain)
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
            Text("v1.2.0")
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
    let locale: Locale

    var body: some View {
        Label {
            Text(L10n.tr(dest.localizationKey, locale: locale))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: dest.systemImage)
        }
        .labelStyle(.titleAndIcon)
        .foregroundStyle(isSelected ? Color.primary : Color.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
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
