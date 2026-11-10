import SwiftUI

struct IslandClipShape: Shape {
    var integratesNotchLip: Bool
    var notchLipWidth: CGFloat
    var notchBandHeight: CGFloat
    var expandedBelowLip: Bool
    var capsule: Bool
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        if integratesNotchLip {
            let growsBelow = expandedBelowLip || rect.height > notchBandHeight + 0.5
            return IslandIntegratedShape(
                notchLipWidth: notchLipWidth,
                notchBandHeight: notchBandHeight,
                cornerRadius: cornerRadius,
                expandedBelowLip: growsBelow
            ).path(in: rect)
        } else if capsule {
            return Capsule(style: .continuous).path(in: rect)
        } else {
            return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).path(in: rect)
        }
    }
}

/// One continuous black surface: narrow physical notch lip on top, optional wider body below with square shoulders.
struct IslandIntegratedShape: Shape {
    var notchLipWidth: CGFloat
    var notchBandHeight: CGFloat
    var cornerRadius: CGFloat
    /// When false, only the menu-bar lip is drawn (rounded bottom). When true, body continues below with flat lip underside.
    var expandedBelowLip: Bool

    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let band = min(notchBandHeight, height)
        let lipW = min(max(notchLipWidth, 1), width)
        let lipX = (width - lipW) / 2
        let radius = min(cornerRadius, min(width, height) / 2)

        if !expandedBelowLip || height <= band + 0.5 {
            return UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: radius,
                bottomTrailingRadius: radius,
                topTrailingRadius: 0,
                style: .continuous
            ).path(in: CGRect(x: lipX, y: 0, width: lipW, height: height))
        }

        var path = Path()
        let left = rect.minX + lipX
        let right = left + lipW
        let top = rect.minY
        let bandY = rect.minY + band
        let bottom = rect.maxY

        path.move(to: CGPoint(x: left, y: top))
        path.addLine(to: CGPoint(x: right, y: top))
        path.addLine(to: CGPoint(x: right, y: bandY))
        path.addLine(to: CGPoint(x: rect.maxX, y: bandY))
        path.addLine(to: CGPoint(x: rect.maxX, y: bottom - radius))
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: bottom - radius),
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: bottom))
        path.addArc(
            center: CGPoint(x: rect.minX + radius, y: bottom - radius),
            radius: radius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX, y: bandY))
        path.addLine(to: CGPoint(x: left, y: bandY))
        path.closeSubpath()
        return path
    }
}

/// Deep-black island surface aligned with the physical notch lip when requested.
struct IslandChrome: View {
    let size: CGSize
    let notchLipWidth: CGFloat
    let notchBandHeight: CGFloat
    let cornerRadius: CGFloat
    let opacity: Double
    let integratesNotch: Bool
    let expandedBelowLip: Bool

    init(
        size: CGSize,
        cornerRadius: CGFloat,
        opacity: Double,
        integratesNotch: Bool,
        notchLipWidth: CGFloat,
        notchBandHeight: CGFloat,
        expandedBelowLip: Bool
    ) {
        self.size = size
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.integratesNotch = integratesNotch
        self.notchLipWidth = notchLipWidth
        self.notchBandHeight = notchBandHeight
        self.expandedBelowLip = expandedBelowLip
    }

    var body: some View {
        IslandIntegratedShape(
            notchLipWidth: integratesNotch ? notchLipWidth : size.width,
            notchBandHeight: integratesNotch ? notchBandHeight : 0,
            cornerRadius: cornerRadius,
            expandedBelowLip: integratesNotch && expandedBelowLip
        )
        .fill(Color.black.opacity(opacity))
        .frame(width: size.width, height: size.height)
    }
}
