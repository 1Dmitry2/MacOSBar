import AppKit
import CoreGraphics
import HubCore
import HubDynamicIsland
import HubSettings
import SwiftUI

struct DynamicIslandSettingsView: View {
    @Bindable private var island = DynamicIslandConfiguration.shared
    @Bindable private var appConfig = AppConfiguration.shared
    @State private var running = DynamicIslandController.shared.isRunning
    @State private var previewMode: IslandPresentationMode = .idle
    @State private var previewAnimationGeneration = 0
    @Environment(\.locale) private var locale
    private let screens = HubDisplayResolver.availableScreens()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                applyModeSection
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

    private var applyModeSection: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $island.liveApplyEnabled) {
                    LText("island.liveApply")
                }
                if !island.liveApplyEnabled {
                    Text(L10n.tr("island.manualApply.hint", locale: locale))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if island.pendingChanges {
                        Text(L10n.tr("island.pendingChanges", locale: locale))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(HubTheme.accentPurple)
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("nav.dynamicIsland", locale: locale))
                .font(.largeTitle.bold())
            Text(L10n.tr("island.subtitle", locale: locale))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Toggle(isOn: $island.dynamicIslandEnabled) {
                    LText("island.enable")
                }
                .onChange(of: island.dynamicIslandEnabled) { _, _ in
                    if !island.liveApplyEnabled {
                        island.applyPendingChanges()
                    }
                    DynamicIslandController.shared.applySettingsChange()
                    running = DynamicIslandController.shared.isRunning
                }
                statusPill
                Spacer()
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
                DynamicIslandPreview(mode: $previewMode, animationGeneration: previewAnimationGeneration)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(IslandPresentationMode.allCases) { mode in
                            modeChip(mode)
                        }
                    }
                }

                Button(L10n.tr("island.preview.playAnimation", locale: locale)) {
                    previewAnimationGeneration += 1
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
            get: { source.isEnabled(in: island) },
            set: { source.setEnabled($0, in: island) }
        )
    }

    private var behaviorSection: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 12) {
                LText("island.behavior").font(.headline)

                Toggle(isOn: $island.islandHoverExpands) {
                    Text(L10n.tr("island.hoverExpands", locale: locale))
                }

                Toggle(isOn: $island.islandClickExpands) {
                    Text(L10n.tr("island.clickExpands", locale: locale))
                }

                Toggle(isOn: $island.islandMediaExpandOnTrackChange) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.tr("island.media.expandOnTrack", locale: locale))
                        Text(L10n.tr("island.media.expandOnTrack.note", locale: locale))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $appConfig.dynamicIslandAutostart) {
                    Text(L10n.tr("island.autostart", locale: locale))
                }

                HStack {
                    Text(L10n.tr("island.hoverDelay", locale: locale))
                    Spacer()
                    Text(String(format: "%.2f s", island.islandHoverDelaySeconds))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $island.islandHoverDelaySeconds, in: 0...1.5, step: 0.05)

                HStack {
                    Text(L10n.tr("island.autoCollapse", locale: locale))
                    Spacer()
                    Text(collapseLabel)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $island.islandAutoCollapseSeconds, in: 0...30, step: 1)

                HStack {
                    Text(L10n.tr("island.notificationDuration", locale: locale))
                    Spacer()
                    Text(String(format: L10n.tr("island.autoCollapse.seconds", locale: locale), Int(island.islandNotificationDurationSeconds)))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $island.islandNotificationDurationSeconds, in: 2...15, step: 1)

                Toggle(isOn: $island.islandMultiActivityEnabled) {
                    Text(L10n.tr("island.multiActivity", locale: locale))
                }

                if island.islandMultiActivityEnabled {
                    Stepper(
                        value: $island.islandMaxCompactActivityIcons,
                        in: 1...5
                    ) {
                        Text(String(format: L10n.tr("island.maxCompactIcons", locale: locale), island.islandMaxCompactActivityIcons))
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
        Toggle(isOn: binding(for: widget)) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.tr(widget.localizationKey, locale: locale))
                    .font(.subheadline.weight(.medium))
                Text(widgetSubtitle(widget))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .toggleStyle(.switch)
        .tint(HubTheme.successGreen)
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
        case .time: return $island.islandWidgetShowsTime
        case .date: return $island.islandWidgetShowsDate
        case .cpu: return $island.islandWidgetShowsCPU
        case .ram: return $island.islandWidgetShowsRAM
        case .disk: return $island.islandWidgetShowsDisk
        case .battery: return $island.islandWidgetShowsBattery
        case .network: return $island.islandWidgetShowsNetwork
        case .temp: return $island.islandWidgetShowsTemperature
        case .music: return $island.islandWidgetShowsMusic
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

                Picker(L10n.tr("island.display", locale: locale), selection: $island.islandDisplayMode) {
                    Text(L10n.tr("island.display.builtIn", locale: locale)).tag(IslandDisplayMode.builtIn)
                    Text(L10n.tr("island.display.main", locale: locale)).tag(IslandDisplayMode.mainDisplay)
                    Text(L10n.tr("island.display.specific", locale: locale)).tag(IslandDisplayMode.specific)
                }

                if island.islandDisplayMode == .specific {
                    Picker(L10n.tr("island.display.pick", locale: locale), selection: displayIDBinding) {
                        ForEach(screens, id: \.id) { screen in
                            Text(screenTitle(screen)).tag(Optional(screen.id))
                        }
                    }
                }

                Text(L10n.tr("island.placement.notchNote", locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var collapseLabel: String {
        if island.islandAutoCollapseSeconds <= 0 {
            return L10n.tr("island.autoCollapse.off", locale: locale)
        }
        return String(format: L10n.tr("island.autoCollapse.seconds", locale: locale), Int(island.islandAutoCollapseSeconds))
    }

    private var controlButtons: some View {
        HStack {
            Button(L10n.tr("island.reset", locale: locale)) {
                island.resetAppearanceToDefaults()
                syncLiveIslandIfNeeded()
            }
            if !island.liveApplyEnabled {
                Button(L10n.tr("island.revert", locale: locale)) {
                    island.revertPendingChanges()
                }
                .disabled(!island.pendingChanges)
                Button(L10n.tr("island.apply", locale: locale)) {
                    island.applyPendingChanges()
                    running = DynamicIslandController.shared.isRunning
                }
                .buttonStyle(.borderedProminent)
                .disabled(!island.pendingChanges)
            }
            Spacer()
        }
    }

    private var styleControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $island.islandLiquidGlassEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.tr("island.style.liquidGlass", locale: locale))
                    Text(L10n.tr("island.style.liquidGlass.note", locale: locale))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if island.islandLiquidGlassEnabled {
                Slider(value: $island.islandLiquidGlassTintOpacity, in: 0.06...0.72) {
                    Text(L10n.tr("island.style.liquidGlass.tint", locale: locale))
                }
                Text(L10n.tr("island.style.liquidGlass.tint.note", locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ColorPicker(
                L10n.tr("island.style.chromeColor", locale: locale),
                selection: chromeColorBinding,
                supportsOpacity: false
            )
            ColorPicker(
                L10n.tr("island.style.accentColor", locale: locale),
                selection: accentColorBinding,
                supportsOpacity: false
            )
            ColorPicker(
                L10n.tr("island.style.textColor", locale: locale),
                selection: foregroundColorBinding,
                supportsOpacity: false
            )
            Slider(value: $island.islandBackgroundOpacity, in: 0.15...1) {
                Text(L10n.tr("island.style.opacity", locale: locale))
            }
            Text(L10n.tr("island.style.opacity.note", locale: locale))
                .font(.caption)
                .foregroundStyle(.secondary)
            Slider(value: $island.islandCornerRadius, in: 12...32, step: 1) {
                Text(L10n.tr("island.style.radius", locale: locale))
            }
            Text(L10n.tr("island.style.compactAuto", locale: locale))
                .font(.caption)
                .foregroundStyle(.secondary)
            Slider(value: $island.islandExpandedWidth, in: 280...720, step: 4) {
                Text(L10n.tr("island.style.expandedWidth", locale: locale))
            }
            Slider(value: $island.islandExpandedHeight, in: 160...360, step: 4) {
                Text(L10n.tr("island.style.expandedHeight", locale: locale))
            }
            Slider(value: $island.islandAnimationDuration, in: 0.15...0.8, step: 0.05) {
                Text(L10n.tr("island.style.animation", locale: locale))
            }
        }
    }

    private func syncLiveIslandIfNeeded() {
        guard island.liveApplyEnabled else { return }
        DynamicIslandController.shared.applySettingsChange()
        running = DynamicIslandController.shared.isRunning
    }

    private var chromeColorBinding: Binding<Color> {
        colorBinding(
            get: { island.islandChromeColor },
            set: { island.islandChromeColor = $0 }
        )
    }

    private var accentColorBinding: Binding<Color> {
        colorBinding(
            get: { island.islandAccentColor },
            set: { island.islandAccentColor = $0 }
        )
    }

    private var foregroundColorBinding: Binding<Color> {
        colorBinding(
            get: { island.islandForegroundColor },
            set: { island.islandForegroundColor = $0 }
        )
    }

    private func colorBinding(
        get: @escaping () -> ColorComponents,
        set: @escaping (ColorComponents) -> Void
    ) -> Binding<Color> {
        Binding(
            get: { swiftUIColor(from: get()) },
            set: { set(components(from: $0)) }
        )
    }

    private func swiftUIColor(from components: ColorComponents) -> Color {
        Color(red: components.red, green: components.green, blue: components.blue)
    }

    private func components(from color: Color) -> ColorComponents {
        let ns = NSColor(color)
        let rgb = ns.usingColorSpace(.deviceRGB) ?? ns
        return ColorComponents(red: rgb.redComponent, green: rgb.greenComponent, blue: rgb.blueComponent)
    }

    private var displayIDBinding: Binding<CGDirectDisplayID?> {
        Binding(
            get: { island.islandDisplayID },
            set: { island.islandDisplayID = $0 }
        )
    }

    private func screenTitle(_ screen: (id: CGDirectDisplayID, name: String, builtIn: Bool)) -> String {
        if screen.builtIn {
            return "\(screen.name) · \(L10n.tr("island.display.builtIn", locale: locale))"
        }
        return screen.name
    }
}
