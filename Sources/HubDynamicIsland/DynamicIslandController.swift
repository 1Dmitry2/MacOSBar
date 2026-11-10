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
        level = .mainMenu + 2
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovable = false
        isMovableByWindowBackground = false
        contentView = content
    }

    public override var canBecomeKey: Bool { true }
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
            integratesNotch: layout.hasNotch,
            notchBandHeight: layout.notchBandHeight,
            expandedBodyHeight: layout.expandedBodyHeight
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

    var body: some View {
        DynamicIslandView(
            metrics: state.metrics,
            mode: presentationMode,
            clock: clock,
            interactive: true,
            loadLiveData: true,
            animatesSizeChanges: true,
            onTap: {
                guard DynamicIslandConfiguration.shared.runtimeSnapshot.clickExpands else { return }
                DynamicIslandController.shared.toggleExpanded()
            },
            onHoverChanged: { inside in
                DynamicIslandController.shared.handleHover(inside)
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        .onChange(of: state.metrics) { _, _ in
            DynamicIslandController.shared.updateHitTestingRect(
                metrics: state.metrics,
                mode: presentationMode
            )
        }
        .onAppear {
            DynamicIslandController.shared.updateHitTestingRect(
                metrics: state.metrics,
                mode: presentationMode
            )
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
        let panelFrame = layout.panelFrame()
        let root = IslandHostView(state: panelState)
        let hosting = IslandPassThroughHostingView(rootView: root)
        hosting.frame = CGRect(origin: .zero, size: panelFrame.size)
        hosting.interactiveRect = IslandInteractiveRect.compute(
            hostSize: panelFrame.size,
            metrics: panelState.metrics,
            mode: .idle
        )

        let panel = DynamicIslandPanel(content: hosting, frame: panelFrame)
        self.hosting = hosting
        self.panel = panel
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

    public func toggleExpanded() {
        guard panel != nil else { return }
        IslandStateManager.shared.toggleExpanded()
        scheduleAutoCollapse()
    }

    public func setExpanded(_ value: Bool, animated: Bool) {
        guard panel != nil else { return }
        IslandStateManager.shared.setExpanded(value, source: .programmatic)
        if value { scheduleAutoCollapse() } else { cancelAutoCollapse() }
        _ = animated
    }

    public func handleHover(_ inside: Bool) {
        guard panel != nil else { return }
        IslandStateManager.shared.hoverChanged(
            inside: inside,
            hoverExpands: DynamicIslandConfiguration.shared.runtimeSnapshot.hoverExpands
        )
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
        let frame = fresh.panelFrame(topAnchorY: fresh.topAnchorY)
        hosting?.frame = CGRect(origin: .zero, size: frame.size)
        let duration = IslandAnimationPolicy.panelDuration
        if animated, duration > 0.02 {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = duration
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }
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
            mode: mode
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
}
