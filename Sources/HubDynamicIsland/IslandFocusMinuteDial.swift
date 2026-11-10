import SwiftUI

struct IslandFocusMinuteDial: View {
    @Binding var minutes: Int
    let accent: Color
  private let marks = Array(stride(from: 5, through: 60, by: 5))

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geo in
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 0) {
                            Color.clear.frame(width: max(0, geo.size.width / 2 - 8))
                            ForEach(marks, id: \.self) { mark in
                                dialMark(mark)
                                    .id(mark)
                            }
                            Color.clear.frame(width: max(0, geo.size.width / 2 - 8))
                        }
                    }
                    .onAppear {
                        proxy.scrollTo(minutes, anchor: .center)
                    }
                    .onChange(of: minutes) { _, value in
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(value, anchor: .center)
                        }
                    }
                }
            }
            .frame(height: 38)

            VStack(spacing: 0) {
                Triangle()
                    .fill(Color.white)
                    .frame(width: 10, height: 6)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 34)
            }
            .allowsHitTesting(false)
        }
        .frame(height: 44)
    }

    private func dialMark(_ mark: Int) -> some View {
        let selected = mark == minutes
        return VStack(spacing: 3) {
            Text("\(mark)")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(selected ? accent : accent.opacity(0.55))
                .opacity(mark % 10 == 0 || mark == 5 ? 1 : 0)
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(selected ? accent : Color.white.opacity(0.22))
                .frame(width: 2, height: selected ? 20 : 12)
        }
        .frame(width: 14)
        .contentShape(Rectangle())
        .onTapGesture { minutes = mark }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
