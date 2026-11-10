import AppKit
import Darwin
import Foundation

enum ProcessNameResolver {
    static func displayName(pid: pid_t, shortComm: String) -> String {
        if let app = NSRunningApplication(processIdentifier: pid) {
            if let localized = app.localizedName, !localized.isEmpty {
                return localized
            }
            if let bundle = app.bundleIdentifier, !bundle.isEmpty {
                return bundle
            }
        }

        var buffer = [CChar](repeating: 0, count: 2_048)
        let status = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        if status > 0 {
            let path = String(cString: buffer)
            let base = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
            if !base.isEmpty { return base }
        }

        var name = [CChar](repeating: 0, count: 256)
        let infoStatus = proc_name(pid, &name, UInt32(name.count))
        if infoStatus > 0 {
            let procName = String(cString: name)
            if !procName.isEmpty { return procName }
        }

        return shortComm
    }

    static func executablePath(pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: 2_048)
        guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return nil }
        return String(cString: buffer)
    }

    static func bundleIdentifier(pid: pid_t) -> String? {
        NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
    }
}
