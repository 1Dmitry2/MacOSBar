import HubCore
import Observation

@MainActor
@Observable
final class NavigationState {
    var selection: HubDestination = .overview

    static let shared = NavigationState()
}
