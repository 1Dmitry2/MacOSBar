import Darwin
import Foundation

public enum HubDestination: String, CaseIterable, Identifiable, Hashable, Sendable {
    case overview
    case smartCleaner
    case systemMonitor
    case deviceControl
    case dynamicIsland
    case diagnostics
    case settings

    public var id: String { rawValue }

    public var systemImage: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .smartCleaner: return "sparkles"
        case .systemMonitor: return "waveform.path.ecg"
        case .deviceControl: return "keyboard"
        case .dynamicIsland: return "capsule.portrait"
        case .settings: return "gearshape"
        case .diagnostics: return "stethoscope"
        }
    }
}

public struct MacSummary: Sendable, Equatable {
    public var hostName: String
    public var deviceName: String
    public var osVersionString: String
    public var osMarketingName: String
    public var chipName: String
    public var modelName: String
    public var physicalMemoryBytes: UInt64
    public var architecture: String

    public var physicalMemoryGB: Double {
        Double(physicalMemoryBytes) / 1_073_741_824
    }

    public static func current() -> MacSummary {
        let ver = ProcessInfo.processInfo.operatingSystemVersion
        let os = "macOS \(ver.majorVersion).\(ver.minorVersion).\(ver.patchVersion)"
        let marketing = macOSMarketingName(major: ver.majorVersion, minor: ver.minorVersion)
        let modelID = sysctlString("hw.model") ?? "Mac"
        let brand = sysctlString("machdep.cpu.brand_string") ?? modelID
        let arch: String
        #if arch(arm64)
        arch = "Apple Silicon (arm64)"
        #else
        arch = "Intel (x86_64)"
        #endif
        return MacSummary(
            hostName: Host.current().localizedName ?? "Mac",
            deviceName: Host.current().localizedName ?? ProcessInfo.processInfo.hostName,
            osVersionString: os,
            osMarketingName: marketing,
            chipName: brand.trimmingCharacters(in: .whitespacesAndNewlines),
            modelName: friendlyMacModel(modelID),
            physicalMemoryBytes: ProcessInfo.processInfo.physicalMemory,
            architecture: arch
        )
    }

    private static func macOSMarketingName(major: Int, minor: Int) -> String {
        switch (major, minor) {
        case (15, _): return "Sequoia"
        case (14, _): return "Sonoma"
        case (13, _): return "Ventura"
        default: return "macOS"
        }
    }

    private static func friendlyMacModel(_ identifier: String) -> String {
        let map: [String: String] = [
            "Mac15,12": "MacBook Air (M3)",
            "Mac15,13": "MacBook Air (M3)",
            "Mac14,15": "MacBook Air (M2)",
            "Mac14,2": "MacBook Air (M2)",
            "Mac14,7": "MacBook Pro (M2)",
            "Mac15,3": "MacBook Pro (M3)",
            "Mac15,6": "MacBook Pro (M3)",
        ]
        return map[identifier] ?? identifier
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
