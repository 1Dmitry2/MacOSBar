import SwiftUI

struct IslandFocusCompactCapsule: View {
    let remainingSeconds: Int
    let totalSeconds: Int
    let accent: Color

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return min(1, max(0, Double(totalSeconds - remainingSeconds) / Double(totalSeconds)))
    }

    private var label: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(accent.opacity(0.28), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 24, height: 24)
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(accent)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
