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
    var background: Color = .black
    var liquidGlass: Bool = true
    var glassTintOpacity: Double = 0.24

    var body: some View {
        let shape = IslandClipShape(
            integratesNotchLip: integratesNotch,
            capsule: false,
            cornerRadius: cornerRadius
        )
        let tint = min(0.82, max(0.04, glassTintOpacity))
        let glassFill = min(0.88, tint * opacity)
        Group {
            if liquidGlass {
                shape
                    .fill(.clear)
                    .background(.thinMaterial, in: shape)
                    .overlay(shape.fill(background.opacity(glassFill)))
                    .overlay(shape.stroke(Color.white.opacity(0.1), lineWidth: 0.8))
            } else {
                shape.fill(background.opacity(opacity))
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}
