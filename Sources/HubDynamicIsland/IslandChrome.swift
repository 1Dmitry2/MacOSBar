import SwiftUI

struct IslandClipShape: Shape {
    var integratesNotchLip: Bool
    var capsule: Bool
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        if integratesNotchLip {
            let radius = min(cornerRadius, min(rect.width, rect.height) / 2)
            return UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: radius,
                bottomTrailingRadius: radius,
                topTrailingRadius: 0,
                style: .continuous
            ).path(in: rect)
        }
        if capsule {
            return Capsule(style: .continuous).path(in: rect)
        }
        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).path(in: rect)
    }
}

/// Single lip/body surface: flat top (display edge), rounded bottom corners only — morphs width/height on expand.
struct IslandChrome: View {
    let size: CGSize
    let cornerRadius: CGFloat
    let opacity: Double
    let integratesNotch: Bool

    var body: some View {
        IslandClipShape(
            integratesNotchLip: integratesNotch,
            capsule: false,
            cornerRadius: cornerRadius
        )
        .fill(Color.black.opacity(opacity))
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}
