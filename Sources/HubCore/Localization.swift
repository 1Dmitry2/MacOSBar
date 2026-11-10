import Foundation
import HubSettings
import SwiftUI

public extension HubDestination {
    var localizationKey: String {
        switch self {
        case .overview: return "nav.overview"
        case .smartCleaner: return "nav.smartCleaner"
        case .systemMonitor: return "nav.systemMonitor"
        case .deviceControl: return "nav.deviceControl"
        case .dynamicIsland: return "nav.dynamicIsland"
        case .settings: return "nav.settings"
        case .diagnostics: return "nav.diagnostics"
        }
    }
}

public extension HubModuleID {
    var localizationKey: String {
        switch self {
        case .smartCleaner: return "module.smartCleaner"
        case .systemMonitor: return "module.systemMonitor"
        case .deviceControl: return "module.deviceControl"
        case .dynamicIsland: return "module.dynamicIsland"
        case .diagnostics: return "module.diagnostics"
        }
    }
}
