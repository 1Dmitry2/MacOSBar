import AppKit
import Combine
import HubCore
import HubDiagnostics
import HubSettings
import HubSystemMonitor
import SwiftUI

public final class DynamicIslandPanel: NSPanel {
    public init(content: NSView, frame: CGRect) {
        super.init(
            contentRect: frame,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .mainMenu + 3
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        hidesOnDeactivate = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovable = false
        isMovableByWindowBackground = false
        acceptsMouseMovedEvents = true
        contentView = content
    }

    public override var canBecomeKey: Bool { true }

    public override var canBecomeMain: Bool { false }
}

@MainActor
final class IslandPanelState: ObservableObject {
    @Published var layout: NotchLayout?

    var interaction: IslandStateManager { IslandStateManager.shared }

    var metrics: IslandLayoutMetrics {
        guard let layout else { return .preview() }
        return IslandLayoutMetrics(
            compactSize: layout.compactSize,
            expandedSize: layout.expandedSize,
            compactPillWidth: layout.compactPillWidth,
            integratesNotch: layout.hasNotch,
            notchBandHeight: layout.notchBandHeight,
            expandedBodyHeight: layout.expandedBodyHeight,
            menuBarBandHeight: layout.menuBarBandHeight
        )
    }
}

struct IslandHostView: View {
    @ObservedObject var state: IslandPanelState
    @ObservedObject private var interaction = IslandStateManager.shared
    @StateObject private var clock = IslandClock()

    private var presentationMode: IslandPresentationMode {
        interaction.presentationMode
    }

    private var canvasSize: CGSize {
        IslandOverlayLayout.canvasSize(metrics: state.metrics, mode: presentationMode)
    }

    var body: some View {
        VStack(spacing: 0) {
            DynamicIslandView(
                metrics: state.metrics,
                mode: presentationMode,
                clock: clock,
                interactive: true,
                loadLiveData: true,
                animatesSizeChanges: true,
                onTap: {
                    DynamicIslandController.shared.handleIslandTap()
                }
            )
            .frame(maxWidth: .infinity, alignment: .top)
            Spacer(minLength: 0)
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
        .ignoresSafeArea(.container, edges: .top)
        .background {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
        }
        .onChange(of: presentationMode) { _, mode in
            DynamicIslandController.shared.updateHitTestingRect(
                metrics: state.metrics,
                mode: mode
            )
        }
        .onChange(of: interaction.phase) { _, _ in
            DynamicIslandController.shared.updateHitTestingRect(
                metrics: state.metrics,
                mode: interaction.presentationMode
            )
        }
        .onChange(of: state.metrics) { _, metrics in
            DynamicIslandController.shared.updateHitTestingRect(
                metrics: metrics,
                mode: interaction.presentationMode
            )
        }
        .onAppear {
            DynamicIslandController.shared.syncPanelVisualFrame(animated: false)
        }
        .onChange(of: interaction.phase) { _, _ in
            DynamicIslandController.shared.syncPanelVisualFrame(animated: true)
        }
    }
}

@MainActor
public final class DynamicIslandController: NSObject {
    public static let shared = DynamicIslandController()

    private var panel: DynamicIslandPanel?
    private var hosting: IslandPassThroughHostingView<IslandHostView>?
    private let panelState = IslandPanelState()
    private let log = HubLogger.log(.island)
    private var screenObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var collapseTimer: Timer?
    private var configObserver: NSObjectProtocol?
    private var draftObserver: NSObjectProtocol?
    private var spaceObserver: NSObjectProtocol?

    public var isRunning: Bool { panel != nil }
    public var isExpanded: Bool { IslandStateManager.shared.isExpanded }

    private override init() {
        super.init()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.reposition(animated: false) }
        }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reposition(animated: false)
                if DynamicIslandController.shared.isRunning {
                    SystemEventManager.shared.stop()
                    SystemEventManager.shared.start()
                }
            }
        }
        configObserver = NotificationCenter.default.addObserver(
            forName: DynamicIslandConfiguration.Notifications.appliedDidChange,
            object: DynamicIslandConfiguration.shared,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.syncFromConfiguration() }
        }
        draftObserver = NotificationCenter.default.addObserver(
            forName: DynamicIslandConfiguration.Notifications.draftDidChange,
            object: DynamicIslandConfiguration.shared,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard DynamicIslandConfiguration.shared.liveApplyEnabled else { return }
                self?.syncFromConfiguration()
            }
        }
        spaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reposition(animated: false)
            }
        }
    }

    public func syncFromConfiguration() {
        applySettingsChange()
        reloadIslandAppearance()
    }

    public func startIfEnabled() {
        guard DynamicIslandConfiguration.shared.runtimeSnapshot.dynamicIslandEnabled else {
            stop()
            return
        }
        if panel != nil {
            reposition(animated: false)
            return
        }
        guard let layout = NotchLayout.detect() else { return }

        panelState.layout = layout
        IslandStateManager.shared.reset()
        let mode = IslandStateManager.shared.presentationMode
        let canvas = IslandOverlayLayout.canvasSize(metrics: panelState.metrics, mode: mode)
        let panelFrame = overlayFrame(for: layout, mode: mode)
        let root = IslandHostView(state: panelState)
        let hosting = IslandPassThroughHostingView(rootView: root)
        hosting.onPointerHover = { [weak self] in self?.handleHover($0) }
        hosting.onIslandClick = { [weak self] in self?.handleIslandTap() }
        hosting.frame = CGRect(origin: .zero, size: canvas)
        hosting.interactiveRect = IslandInteractiveRect.compute(
            hostSize: canvas,
            metrics: panelState.metrics,
            mode: mode,
            isFlipped: hosting.isFlipped
        )

        let panel = DynamicIslandPanel(content: hosting, frame: panelFrame)
        self.hosting = hosting
        self.panel = panel
        if IslandSkyLightOperator.shared.isAvailable {
            IslandSkyLightOperator.shared.delegateWindow(panel)
        }
        panel.orderFrontRegardless()
        SystemEventManager.shared.start()
        log.info("Dynamic Island shown on \(layout.screen.localizedName)")
    }

    public func stop() {
        collapseTimer?.invalidate()
        collapseTimer = nil
        panel?.close()
        panel = nil
        hosting = nil
        panelState.layout = nil
        SystemEventManager.shared.stop()
        IslandStateManager.shared.reset()
    }

    public func focusPanelIfNeeded() {
        panel?.makeKeyAndOrderFront(nil)
    }

    public func handleIslandTap() {
        guard let panel else { return }
        panel.makeKeyAndOrderFront(nil)
        let config = DynamicIslandConfiguration.shared.runtimeSnapshot
        guard config.clickExpands else { return }
        let state = IslandStateManager.shared
        guard !state.isExpanded else { return }
        state.openFromTap()
        syncPanelVisualFrame(animated: true)
        scheduleAutoCollapse()
    }

    public func toggleExpanded() {
        guard panel != nil else { return }
        IslandStateManager.shared.toggleExpanded()
        syncPanelVisualFrame(animated: true)
        scheduleAutoCollapse()
    }

    public func setExpanded(_ value: Bool, animated: Bool) {
        guard panel != nil else { return }
        IslandStateManager.shared.setExpanded(value, source: .programmatic)
        syncPanelVisualFrame(animated: animated)
        if value { scheduleAutoCollapse() } else { cancelAutoCollapse() }
    }

    public func handleHover(_ inside: Bool) {
        guard panel != nil else { return }
        let before = IslandStateManager.shared.presentationMode
        IslandStateManager.shared.hoverChanged(
            inside: inside,
            hoverExpands: DynamicIslandConfiguration.shared.runtimeSnapshot.hoverExpands
        )
        let after = IslandStateManager.shared.presentationMode
        if before != after || before.isExpandedLayout != after.isExpandedLayout {
            syncPanelVisualFrame(animated: true)
        }
        hosting?.reconcilePointerHover()
        if IslandStateManager.shared.isExpanded {
            scheduleAutoCollapse()
        } else {
            cancelAutoCollapse()
        }
    }

    public func reposition(animated: Bool) {
        guard let panel, let fresh = NotchLayout.detect(screen: HubDisplayResolver.resolvedIslandScreen()) else {
            if panel == nil, DynamicIslandConfiguration.shared.runtimeSnapshot.dynamicIslandEnabled { startIfEnabled() }
            return
        }
        panelState.layout = fresh
        let mode = IslandStateManager.shared.presentationMode
        let canvas = IslandOverlayLayout.canvasSize(metrics: panelState.metrics, mode: mode)
        let frame = overlayFrame(for: fresh, mode: mode)
        hosting?.frame = CGRect(origin: .zero, size: canvas)
        panel.setFrame(frame, display: true)
        syncPanelVisualFrame(animated: animated)
        panel.orderFrontRegardless()
    }

    public func applySettingsChange() {
        if DynamicIslandConfiguration.shared.runtimeSnapshot.dynamicIslandEnabled {
            if panel == nil {
                startIfEnabled()
            } else if let screen = HubDisplayResolver.resolvedIslandScreen() {
                panelState.layout = NotchLayout.detect(screen: screen)
                reposition(animated: true)
            }
        } else {
            stop()
        }
    }

    public func updateHitTestingRect(metrics: IslandLayoutMetrics, mode: IslandPresentationMode) {
        guard let hosting else { return }
        hosting.interactiveRect = IslandInteractiveRect.compute(
            hostSize: hosting.bounds.size,
            metrics: metrics,
            mode: mode,
            isFlipped: hosting.isFlipped
        )
    }

    public func reloadIslandAppearance() {
        if let screen = HubDisplayResolver.resolvedIslandScreen() {
            panelState.layout = NotchLayout.detect(screen: screen)
            reposition(animated: false)
        }
    }

    private func scheduleAutoCollapse() {
        cancelAutoCollapse()
        let interval = DynamicIslandConfiguration.shared.runtimeSnapshot.autoCollapseSeconds
        guard interval > 0, IslandStateManager.shared.isExpanded else { return }
        collapseTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.setExpanded(false, animated: true)
            }
        }
    }

    private func cancelAutoCollapse() {
        collapseTimer?.invalidate()
        collapseTimer = nil
    }

    public func syncPanelVisualFrame(animated: Bool) {
        guard let panel, let layout = panelState.layout else { return }
        let mode = IslandStateManager.shared.presentationMode
        let canvas = IslandOverlayLayout.canvasSize(metrics: panelState.metrics, mode: mode)
        let frame = overlayFrame(for: layout, mode: mode)
        hosting?.frame = CGRect(origin: .zero, size: canvas)
        updateHitTestingRect(metrics: panelState.metrics, mode: mode)
        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = IslandAnimationPolicy.panelDuration
                panel.animator().setFrame(frame, display: true)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + IslandAnimationPolicy.panelDuration + 0.05) { [weak self] in
                self?.hosting?.reconcilePointerHover()
            }
        } else {
            panel.setFrame(frame, display: true)
            hosting?.reconcilePointerHover()
        }
        panel.orderFrontRegardless()
    }

    private func overlayFrame(for layout: NotchLayout, mode: IslandPresentationMode) -> CGRect {
        IslandOverlayLayout.topAnchoredFrame(
            on: layout.screen,
            metrics: panelState.metrics,
            mode: mode
        )
    }
}
