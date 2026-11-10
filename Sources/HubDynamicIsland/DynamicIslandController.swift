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
            integratesNotch: layout.hasNotch
        )
    }
}

struct IslandHostView: View {
    @ObservedObject var state: IslandPanelState
    @ObservedObject private var interaction = IslandStateManager.shared
    @Bindable private var systemEvents = IslandSystemEventViewModel.shared
    @StateObject private var clock = IslandClock()

    private var resolvedMode: IslandPresentationMode {
        if interaction.phase == .idle, let hint = systemEvents.snapshot.suggestedPresentation {
            return hint
        }
        return interaction.presentationMode
    }

    var body: some View {
        DynamicIslandView(
            metrics: state.metrics,
            mode: resolvedMode,
            clock: clock,
            interactive: true,
            loadLiveData: true,
            animatesSizeChanges: true,
            onTap: {
                guard AppConfiguration.shared.islandClickExpands else { return }
                DynamicIslandController.shared.toggleExpanded()
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onHover { inside in
            DynamicIslandController.shared.handleHover(inside)
        }
    }
}

@MainActor
public final class DynamicIslandController: NSObject {
    public static let shared = DynamicIslandController()

    private var panel: DynamicIslandPanel?
    private var hosting: NSHostingView<IslandHostView>?
    private let panelState = IslandPanelState()
    private let log = HubLogger.log(.island)
    private var screenObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var collapseTimer: Timer?

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
    }

    public func startIfEnabled() {
        guard AppConfiguration.shared.dynamicIslandEnabled else {
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
        let hosting = NSHostingView(rootView: root)
        hosting.frame = CGRect(origin: .zero, size: panelFrame.size)

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
            hoverExpands: AppConfiguration.shared.islandHoverExpands
        )
        if IslandStateManager.shared.isExpanded {
            scheduleAutoCollapse()
        } else if IslandStateManager.shared.phase == .idle {
            cancelAutoCollapse()
        }
    }

    public func reposition(animated: Bool) {
        guard let panel, let fresh = NotchLayout.detect(screen: HubDisplayResolver.resolvedIslandScreen()) else {
            if panel == nil, AppConfiguration.shared.dynamicIslandEnabled { startIfEnabled() }
            return
        }
        panelState.layout = fresh
        let preserveTop = panel.frame.maxY
        let anchorY = abs(preserveTop - fresh.topAnchorY) < 80 ? preserveTop : fresh.topAnchorY
        let frame = fresh.panelFrame(topAnchorY: anchorY)
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
        if AppConfiguration.shared.dynamicIslandEnabled {
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

    public func reloadIslandAppearance() {
        if let screen = HubDisplayResolver.resolvedIslandScreen() {
            panelState.layout = NotchLayout.detect(screen: screen)
            reposition(animated: false)
        }
    }

    private func scheduleAutoCollapse() {
        cancelAutoCollapse()
        let interval = AppConfiguration.shared.islandAutoCollapseSeconds
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
