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
        hasShadow = true
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
    @Published var expanded = false
    @Published var layout: NotchLayout?

    var presentation: IslandPresentationMode {
        expanded ? .expanded : .compact
    }

    var metrics: IslandLayoutMetrics {
        guard let layout else { return .preview() }
        return IslandLayoutMetrics(compactSize: layout.compactSize, expandedSize: layout.expandedSize)
    }
}

struct IslandHostView: View {
    @ObservedObject var state: IslandPanelState
    @StateObject private var clock = IslandClock()

    var body: some View {
        DynamicIslandView(
            metrics: state.metrics,
            mode: state.presentation,
            clock: clock,
            interactive: true,
            loadLiveData: true,
            onTap: { DynamicIslandController.shared.toggleExpanded() }
        )
        .onHover { inside in
            guard AppConfiguration.shared.islandHoverExpands else { return }
            DynamicIslandController.shared.setExpanded(inside, animated: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    public var isExpanded: Bool { panelState.expanded }

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
            Task { @MainActor in self?.reposition(animated: false) }
        }
    }

    public func startIfEnabled() {
        guard AppConfiguration.shared.dynamicIslandEnabled else {
            stop()
            return
        }
        guard panel == nil, let layout = NotchLayout.detect() else { return }

        panelState.layout = layout
        panelState.expanded = false
        let initialFrame = layout.frame(expanded: false)
        let root = IslandHostView(state: panelState)
        let hosting = NSHostingView(rootView: root)
        hosting.frame = CGRect(origin: .zero, size: initialFrame.size)

        let panel = DynamicIslandPanel(content: hosting, frame: initialFrame)
        self.hosting = hosting
        self.panel = panel
        panel.orderFrontRegardless()
        log.info("Dynamic Island shown on \(layout.screen.localizedName)")
    }

    public func stop() {
        collapseTimer?.invalidate()
        collapseTimer = nil
        panel?.close()
        panel = nil
        hosting = nil
        panelState.layout = nil
        panelState.expanded = false
    }

    public func toggleExpanded() {
        guard panel != nil else { return }
        panelState.expanded.toggle()
        reposition(animated: true)
        scheduleAutoCollapse()
    }

    public func setExpanded(_ value: Bool, animated: Bool) {
        guard panel != nil, panelState.expanded != value else { return }
        panelState.expanded = value
        reposition(animated: animated)
        if value { scheduleAutoCollapse() } else { cancelAutoCollapse() }
    }

    public func reposition(animated: Bool) {
        guard let panel, let fresh = NotchLayout.detect(screen: HubDisplayResolver.resolvedIslandScreen()) else {
            if panel == nil, AppConfiguration.shared.dynamicIslandEnabled { startIfEnabled() }
            return
        }
        panelState.layout = fresh
        let frame = fresh.frame(expanded: panelState.expanded)
        hosting?.frame = CGRect(origin: .zero, size: frame.size)
        let duration = IslandAnimationPolicy.panelDuration
        if animated, duration > 0.02 {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = duration
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
        guard interval > 0, panelState.expanded else { return }
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
