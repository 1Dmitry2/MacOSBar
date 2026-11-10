import HubCore
import HubSettings
import SwiftUI

/// Embedded MacBook top-edge preview using the same `DynamicIslandView` as the floating panel.
public struct DynamicIslandPreview: View {
    @Bindable private var island = DynamicIslandConfiguration.shared
    @StateObject private var clock = IslandClock()
    @Binding public var mode: IslandPresentationMode
    public var animationGeneration: Int

    public init(mode: Binding<IslandPresentationMode>, animationGeneration: Int = 0) {
        self._mode = mode
        self.animationGeneration = animationGeneration
    }

    private var metrics: IslandLayoutMetrics { .preview(from: island) }

    private var previewCanvasHeight: CGFloat {
        max(260, metrics.size(for: mode).height + 32)
    }

    public var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.12),
                                Color(white: 0.08),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    }
                    .frame(height: previewCanvasHeight)

                DynamicIslandView(
                    metrics: metrics,
                    mode: mode,
                    clock: clock,
                    interactive: false,
                    nookControlsEnabled: true,
                    loadLiveData: true,
                    animatesSizeChanges: true,
                    onTap: {
                        withAnimation(IslandAnimationPolicy.swiftUIAnimation) {
                            mode = mode.isExpandedLayout ? .idle : .expanded
                        }
                    },
                    onHoverChanged: { inside in
                        withAnimation(IslandAnimationPolicy.swiftUIAnimation) {
                            if inside, !mode.isExpandedLayout {
                                mode = .hover
                            } else if mode == .hover {
                                mode = .idle
                            }
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            Text(L10n.tr("island.preview.caption"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .animation(IslandAnimationPolicy.swiftUIAnimation, value: mode)
        .animation(IslandAnimationPolicy.swiftUIAnimation, value: metrics)
        .animation(IslandAnimationPolicy.swiftUIAnimation, value: island.draftSnapshot)
        .onChange(of: animationGeneration) { _, _ in
            playExpandDemo()
        }
    }

    private func playExpandDemo() {
        let steps: [IslandPresentationMode] = [.idle, .hover, .music, .expanded, .notification, .idle]
        let stepInterval = IslandAnimationPolicy.panelDuration + 0.45
        for (index, step) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * stepInterval) {
                withAnimation(IslandAnimationPolicy.swiftUIAnimation) {
                    mode = step
                }
            }
        }
    }
}
