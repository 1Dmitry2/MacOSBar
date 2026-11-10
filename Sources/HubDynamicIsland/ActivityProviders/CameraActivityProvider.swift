import Foundation
import HubSettings

@MainActor
final class CameraActivityProvider {
    var onChange: ((IslandActivity?) -> Void)?

    nonisolated(unsafe) static let isSupportedByPublicAPI = false

    static var publicAPILimitation: String {
        "Third-party apps cannot detect system-wide camera use via supported public API without opening capture sessions."
    }

    func start() {
        onChange?(nil)
    }

    func stop() {
        onChange?(nil)
    }
}
