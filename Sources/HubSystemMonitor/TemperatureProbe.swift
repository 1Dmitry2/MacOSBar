import Foundation

/// Apple does not expose CPU die temperature through public macOS APIs on Apple Silicon.
/// IOKit power/thermal keys (e.g. legacy SMC) require private interfaces or SIP-breaking tools — not used here.
public enum TemperatureProbe: Sendable {
    public struct Result: Sendable, Equatable {
        public var celsius: Double?
        public var unavailableReasonKey: String

        public static let unavailable = Result(
            celsius: nil,
            unavailableReasonKey: "temp.reason.appleSilicon"
        )
    }

    public static func current() -> Result {
        .unavailable
    }
}
