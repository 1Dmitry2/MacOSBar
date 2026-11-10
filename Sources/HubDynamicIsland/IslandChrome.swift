import SwiftUI

struct IslandClipShape: Shape {
    var capsule: Bool
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        if capsule {
            Capsule(style: .continuous).path(in: rect)
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).path(in: rect)
        }
    }
}

/// Deep-black island surface aligned with the physical notch lip when requested.
struct IslandChrome: View {
    let size: CGSize
    let cornerRadius: CGFloat
    let opacity: Double
    let integratesNotch: Bool
    let expanded: Bool

    var body: some View {
        Group {
            if integratesNotch && !expanded {
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(opacity))
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(opacity))
            }
        }
        .frame(width: size.width, height: size.height)
        .overlay {
            Group {
                if integratesNotch && !expanded {
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.04), lineWidth: 0.5)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5)
                }
            }
        }
    }
}
