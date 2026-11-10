import Foundation

public enum ByteCountFormat {
    public static func string(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    public static func rate(_ bytesPerSecond: Double) -> String {
        let bps = Int64(bytesPerSecond.rounded())
        return "\(string(bps))/s"
    }
}
