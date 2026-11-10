import CoreGraphics
import HubCore
import HubDynamicIsland
import HubSettings
import SwiftUI

struct DynamicIslandSettingsView: View {
    @Bindable private var config = AppConfiguration.shared
    @State private var running = DynamicIslandController.shared.isRunning
    @State private var previewMode: IslandPresentationMode = .idle
    @State private var playPreviewAnimation = false
    @Environment(\.locale) private var locale
    private let screens = HubDisplayResolver.availableScreens()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                previewSection
                eventSourcesSection
                behaviorSection
                widgetsSection
                appearanceSection
                placementSection
                controlButtons
            }
            .padding(24)
        }
        .onAppear { running = DynamicIslandController.shared.isRunning }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("nav.dynamicIsland", locale: locale))
                .font(.largeTitle.bold())
            Text(L10n.tr("island.subtitle", locale: locale))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Toggle(isOn: $config.dynamicIslandEnabled) {
                    LText("island.enable")
                }
                .onChange(of: config.dynamicIslandEnabled) { _, _ in
                    DynamicIslandController.shared.applySettingsChange()
                    running = DynamicIslandController.shared.isRunning
                }
                statusPill
                Spacer()
                Button(L10n.tr("island.showOnDesktop", locale: locale)) {
                    config.dynamicIslandEnabled = true
                    DynamicIslandController.shared.startIfEnabled()
                    running = DynamicIslandController.shared.isRunning
                }
                .buttonStyle(.borderedProminent)
                .tint(HubTheme.accentPurple)
            }
        }
    }

    private var statusPill: some View {
        Text(running ? L10n.tr("status.active", locale: locale) : L10n.tr("status.inactive", locale: locale))
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                (running ? HubTheme.successGreen : Color.secondary.opacity(0.25)).opacity(0.2),
                in: Capsule()
            )
            .foregroundStyle(running ? HubTheme.successGreen : .secondary)
    }

    private var previewSection: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 16) {
                DynamicIslandPreview(mode: $previewMode, animateDemo: playPreviewAnimation)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(IslandPresentationMode.allCases) { mode in
                            modeChip(mode)
                        }
                    }
                }

                Button(L10n.tr("island.preview.playAnimation", locale: locale)) {
                    playPreviewAnimation = false
                    playPreviewAnimation = true
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func modeChip(_ mode: IslandPresentationMode) -> some View {
        let selected = previewMode == mode
        return Button {
            previewMode = mode
        } label: {
            Text(L10n.tr("island.preview.mode.\(mode.rawValue)", locale: locale))
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? HubTheme.accentPurple.opacity(0.18) : Color.primary.opacity(0.05), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(selected ? HubTheme.accentPurple : Color.clear, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var eventSourcesSection: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 12) {
                LText("island.eventSources").font(.headline)
                Text(L10n.tr("island.eventSources.hint", locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(IslandEventSourceID.allCases) { source in
                    eventSourceRow(source)
                }
            }
        }
    }

    private func eventSourceRow(_ source: IslandEventSourceID) -> some View {
        let implemented = source.isImplemented
        let enabled = implemented && source.isEnabled(in: config)
        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.tr(source.localizationKey, locale: locale))
                    .font(.subheadline.weight(.medium))
                if let note = source.limitationText() {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !implemented {
                    Text(L10n.tr("island.event.unavailable", locale: locale))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
            Spacer(minLength: 8)
            Toggle("", isOn: eventSourceBinding(source))
                .labelsHidden()
                .disabled(!implemented)
                .toggleStyle(.switch)
                .tint(HubTheme.successGreen)
                .opacity(implemented ? 1 : 0.45)
        }
        .padding(.vertical, 4)
    }

    private func eventSourceBinding(_ source: IslandEventSourceID) -> Binding<Bool> {
        Binding(
            get: { source.isEnabled(in: config) },
            set: { source.setEnabled($0, in: config) }
        )
    }

    private var behaviorSection: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 12) {
                LText("island.behavior").font(.headline)

                Toggle(isOn: $config.islandHoverExpands) {
                    Text(L10n.tr("island.hoverExpands", locale: locale))
                }

                Toggle(isOn: $config.islandClickExpands) {
                    Text(L10n.tr("island.clickExpands", locale: locale))
                }

                HStack {
                    Text(L10n.tr("island.hoverDelay", locale: locale))
                    Spacer()
                    Text(String(format: "%.2f s", config.islandHoverDelaySeconds))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $config.islandHoverDelaySeconds, in: 0...1.5, step: 0.05)

                HStack {
                    Text(L10n.tr("island.autoCollapse", locale: locale))
                    Spacer()
                    Text(collapseLabel)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $config.islandAutoCollapseSeconds, in: 0...30, step: 1)

                HStack {
                    Text(L10n.tr("island.notificationDuration", locale: locale))
                    Spacer()
                    Text(String(format: L10n.tr("island.autoCollapse.seconds", locale: locale), Int(config.islandNotificationDurationSeconds)))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $config.islandNotificationDurationSeconds, in: 2...15, step: 1)

                Toggle(isOn: $config.islandMultiActivityEnabled) {
                    Text(L10n.tr("island.multiActivity", locale: locale))
                }

                if config.islandMultiActivityEnabled {
                    Stepper(
                        value: $config.islandMaxCompactActivityIcons,
                        in: 1...5
                    ) {
                        Text(String(format: L10n.tr("island.maxCompactIcons", locale: locale), config.islandMaxCompactActivityIcons))
                    }
                }
            }
        }
    }

    private var widgetsSection: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 12) {
                LText("island.widgets").font(.headline)
                Text(L10n.tr("island.widgets.hint", locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(IslandWidgetID.allCases) { widget in
                    widgetRow(widget)
                }
            }
        }
    }

    private func widgetRow(_ widget: IslandWidgetID) -> some View {
        let binding = binding(for: widget)
        let enabled = binding.wrappedValue
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.tr(widget.localizationKey, locale: locale))
                    .font(.subheadline.weight(.medium))
                Text(widgetSubtitle(widget))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                binding.wrappedValue.toggle()
                DynamicIslandController.shared.reloadIslandAppearance()
            } label: {
                Text(
                    enabled
                        ? L10n.tr("island.widget.enabled", locale: locale)
                        : L10n.tr("island.widget.disabled", locale: locale)
                )
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(enabled ? HubTheme.successGreen.opacity(0.18) : Color.secondary.opacity(0.12), in: Capsule())
                .foregroundStyle(enabled ? HubTheme.successGreen : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func widgetSubtitle(_ widget: IslandWidgetID) -> String {
        switch widget {
        case .temp:
            return L10n.tr("island.widget.temp.note", locale: locale)
        default:
            return widget.rawValue.uppercased()
        }
    }

    private func binding(for widget: IslandWidgetID) -> Binding<Bool> {
        switch widget {
        case .time: return $config.islandWidgetShowsTime
        case .date: return $config.islandWidgetShowsDate
        case .cpu: return $config.islandWidgetShowsCPU
        case .ram: return $config.islandWidgetShowsRAM
        case .disk: return $config.islandWidgetShowsDisk
        case .battery: return $config.islandWidgetShowsBattery
        case .network: return $config.islandWidgetShowsNetwork
        case .temp: return $config.islandWidgetShowsTemperature
        case .music: return $config.islandWidgetShowsMusic
        }
    }

    private var appearanceSection: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 12) {
                LText("island.appearance").font(.headline)
                styleControls
            }
        }
    }

    private var placementSection: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 12) {
                LText("island.placement").font(.headline)

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

                Slider(value: $config.islandVerticalOffset, in: -24...24, step: 1) {
                    Text(L10n.tr("island.verticalOffset", locale: locale))
                }
                .onChange(of: config.islandVerticalOffset) { _, _ in
                    DynamicIslandController.shared.reposition(animated: true)
                }
            }
        }
    }

    private var collapseLabel: String {
        if config.islandAutoCollapseSeconds <= 0 {
            return L10n.tr("island.autoCollapse.off", locale: locale)
        }
        return String(format: L10n.tr("island.autoCollapse.seconds", locale: locale), Int(config.islandAutoCollapseSeconds))
    }

    private var controlButtons: some View {
        HStack {
            Button(L10n.tr("island.reset", locale: locale)) {
                config.islandBackgroundOpacity = 0.92
                config.islandCornerRadius = 20
                config.islandCompactHeight = 32
                config.islandExpandedHeight = 76
                config.islandExpandedWidth = 380
                config.islandCompactWidth = 240
                config.islandAnimationDuration = 0.32
                DynamicIslandController.shared.applySettingsChange()
            }
            Spacer()
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

    private var styleControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Slider(value: $config.islandBackgroundOpacity, in: 0.55...1) {
                Text(L10n.tr("island.style.opacity", locale: locale))
            }
            Slider(value: $config.islandCornerRadius, in: 12...32, step: 1) {
                Text(L10n.tr("island.style.radius", locale: locale))
            }
            Slider(value: $config.islandCompactWidth, in: 180...320, step: 4) {
                Text(L10n.tr("island.style.compactWidth", locale: locale))
            }
            Slider(value: $config.islandCompactHeight, in: 28...44, step: 1) {
                Text(L10n.tr("island.style.compactHeight", locale: locale))
            }
            Slider(value: $config.islandExpandedWidth, in: 280...520, step: 4) {
                Text(L10n.tr("island.style.expandedWidth", locale: locale))
            }
            Slider(value: $config.islandExpandedHeight, in: 64...120, step: 2) {
                Text(L10n.tr("island.style.expandedHeight", locale: locale))
            }
            Slider(value: $config.islandAnimationDuration, in: 0.15...0.8, step: 0.05) {
                Text(L10n.tr("island.style.animation", locale: locale))
            }
        }
        .onChange(of: config.islandBackgroundOpacity) { _, _ in DynamicIslandController.shared.reloadIslandAppearance() }
        .onChange(of: config.islandCornerRadius) { _, _ in DynamicIslandController.shared.reloadIslandAppearance() }
        .onChange(of: config.islandCompactWidth) { _, _ in DynamicIslandController.shared.applySettingsChange() }
        .onChange(of: config.islandCompactHeight) { _, _ in DynamicIslandController.shared.applySettingsChange() }
        .onChange(of: config.islandExpandedWidth) { _, _ in DynamicIslandController.shared.applySettingsChange() }
        .onChange(of: config.islandExpandedHeight) { _, _ in DynamicIslandController.shared.applySettingsChange() }
        .onChange(of: config.islandAnimationDuration) { _, _ in DynamicIslandController.shared.reloadIslandAppearance() }
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
