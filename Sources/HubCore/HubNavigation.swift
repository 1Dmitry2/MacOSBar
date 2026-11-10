import Darwin
import Foundation

public enum HubDestination: String, CaseIterable, Identifiable, Sendable {
    case overview
    case smartCleaner
    case systemMonitor
    case deviceControl
    case dynamicIsland
    case settings

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .overview: return "Overview"
        case .smartCleaner: return "Smart Cleaner"
        case .systemMonitor: return "System Monitor"
        case .deviceControl: return "Device Control"
        case .dynamicIsland: return "Dynamic Island"
        case .settings: return "Settings"
        }
    }

    public var systemImage: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .smartCleaner: return "sparkles"
        case .systemMonitor: return "waveform.path.ecg"
        case .deviceControl: return "keyboard"
        case .dynamicIsland: return "capsule.portrait"
        case .settings: return "gearshape"
        }
    }
}

public struct MacSummary: Sendable, Equatable {
    public var hostName: String
    public var osVersion: String
    public var chipName: String
    public var physicalMemoryGB: Double

    public init(hostName: String, osVersion: String, chipName: String, physicalMemoryGB: Double) {
        self.hostName = hostName
        self.osVersion = osVersion
        self.chipName = chipName
        self.physicalMemoryGB = physicalMemoryGB
    }

    public static func current() -> MacSummary {
        let ver = ProcessInfo.processInfo.operatingSystemVersion
        let os = "macOS \(ver.majorVersion).\(ver.minorVersion).\(ver.patchVersion)"
        let mem = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824
        return MacSummary(
            hostName: Host.current().localizedName ?? "Mac",
            osVersion: os,
            chipName: sysctlString("hw.model") ?? "Apple Silicon",
            physicalMemoryGB: mem
        )
    }
}

private func sysctlString(_ name: String) -> String? {
    var size = 0
    sysctlbyname(name, nil, &size, nil, 0)
    guard size > 0 else { return nil }
    var buffer = [CChar](repeating: 0, count: size)
    guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
    return String(cString: buffer)
}
