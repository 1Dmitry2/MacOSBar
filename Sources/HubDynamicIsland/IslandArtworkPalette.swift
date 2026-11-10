import AppKit
import SwiftUI

struct IslandArtworkPalette: Equatable {
    var primary: Color
    var secondary: Color
    var wave: Color

    static func from(artwork: NSImage?, fallback: Color) -> IslandArtworkPalette {
        guard let artwork, let sample = averageColor(in: artwork) else {
            return IslandArtworkPalette(
                primary: fallback,
                secondary: fallback.opacity(0.72),
                wave: .white.opacity(0.92)
            )
        }
        let primary = Color(nsColor: sample)
        return IslandArtworkPalette(
            primary: primary,
            secondary: primary.opacity(0.68),
            wave: contrastingWave(for: sample)
        )
    }

    private static func contrastingWave(for color: NSColor) -> Color {
        guard let rgb = color.usingColorSpace(.deviceRGB) else { return .white.opacity(0.9) }
        let luminance = 0.299 * rgb.redComponent + 0.587 * rgb.greenComponent + 0.114 * rgb.blueComponent
        return luminance > 0.55 ? Color.black.opacity(0.75) : Color.white.opacity(0.92)
    }

    private static func averageColor(in image: NSImage) -> NSColor? {
        let target = CGSize(width: 8, height: 8)
        guard let rep = image.bestRepresentation(for: NSRect(origin: .zero, size: target), context: nil, hints: nil),
              let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                            pixelsWide: Int(target.width),
                                            pixelsHigh: Int(target.height),
                                            bitsPerSample: 8,
                                            samplesPerPixel: 4,
                                            hasAlpha: true,
                                            isPlanar: false,
                                            colorSpaceName: .deviceRGB,
                                            bytesPerRow: 0,
                                            bitsPerPixel: 0) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        rep.draw(in: NSRect(origin: .zero, size: target))
        NSGraphicsContext.restoreGraphicsState()
        guard let data = bitmap.bitmapData else { return nil }
        var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0, count: UInt64 = 0
        let pixelCount = Int(target.width * target.height)
        for i in 0..<pixelCount {
            let offset = i * 4
            let alpha = data[offset + 3]
            guard alpha > 20 else { continue }
            r += UInt64(data[offset])
            g += UInt64(data[offset + 1])
            b += UInt64(data[offset + 2])
            count += 1
        }
        guard count > 0 else { return nil }
        return NSColor(
            red: CGFloat(r / count) / 255,
            green: CGFloat(g / count) / 255,
            blue: CGFloat(b / count) / 255,
            alpha: 1
        )
    }
}

struct IslandAlbumWaveform: View {
    let active: Bool
    let palette: IslandArtworkPalette

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1, paused: !active)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<7, id: \.self) { index in
                    let wave = active ? 4 + abs(sin(phase * 3.2 + Double(index) * 0.85)) * 11 : 3.5
                    Capsule()
                        .fill(palette.wave)
                        .frame(width: 2.5, height: wave)
                }
            }
        }
        .frame(height: 16)
    }
}
