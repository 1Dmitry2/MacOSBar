import Foundation
import HubDiagnostics
import ServiceManagement

enum LoginItemService {
    static func apply(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Registration requires a signed .app bundle with matching identifier.
            HubLogger.log(.app).error("Login item: \(error.localizedDescription)")
        }
    }
}
