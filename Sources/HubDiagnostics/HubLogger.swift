import Foundation
import os

public enum HubLogCategory: String {
    case app, cleaner, monitor, device, island, permissions, settings
}

public enum HubLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.macoshub.app"

    public static func log(_ category: HubLogCategory) -> Logger {
        Logger(subsystem: subsystem, category: category.rawValue)
    }
}
