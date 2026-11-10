import HubCore
import HubSettings
import SwiftUI

/// Embedded MacBook top-edge preview using the same `DynamicIslandView` as the floating panel.
public struct DynamicIslandPreview: View {
    @Bindable private var config = AppConfiguration.shared
    @StateObject private var clock = IslandClock()
    @Binding public var mode: IslandPresentationMode
    public var animateDemo: Bool

    public init(mode: Binding<IslandPresentationMode>, animateDemo: Bool = false) {
        self._mode = mode
        self.animateDemo = animateDemo
    }

    private var metrics: IslandLayoutMetrics { .preview(from: config) }

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
                    .frame(height: 148)

                notchShape
                    .offset(y: 6)

                DynamicIslandView(
                    metrics: metrics,
                    mode: mode,
                    clock: clock,
                    interactive: false,
                    loadLiveData: true,
                    onTap: nil
                )
                .offset(y: 22)
                .shadow(color: .black.opacity(0.45), radius: 12, y: 4)
            }
            Text(L10n.tr("island.preview.caption"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .animation(IslandAnimationPolicy.swiftUIAnimation, value: mode)
        .animation(IslandAnimationPolicy.swiftUIAnimation, value: metrics)
        .onChange(of: animateDemo) { _, run in
            guard run else { return }
            playExpandDemo()
        }
    }

    private var notchShape: some View {
        Capsule()
            .fill(.black)
            .frame(width: min(156, metrics.expandedSize.width * 0.42), height: 28)
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
            }
    }

    private func playExpandDemo() {
        let steps: [IslandPresentationMode] = [.compact, .expanded, .compact]
        for (index, step) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * (IslandAnimationPolicy.panelDuration + 0.35)) {
                mode = step
            }
        }
    }
}
