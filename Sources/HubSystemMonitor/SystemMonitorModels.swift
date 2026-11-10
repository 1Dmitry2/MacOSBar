import Foundation

public struct CPUSnapshot: Sendable, Equatable {
    public var totalUsage: Double
    public var userUsage: Double
    public var systemUsage: Double
    public var coreCount: Int
    public var history: [Double]

    public init(totalUsage: Double, userUsage: Double, systemUsage: Double, coreCount: Int, history: [Double]) {
        self.totalUsage = totalUsage
        self.userUsage = userUsage
        self.systemUsage = systemUsage
        self.coreCount = coreCount
        self.history = history
    }
}

public struct MemorySnapshot: Sendable, Equatable {
    public init(
        totalBytes: UInt64,
        usedBytes: UInt64,
        freeBytes: UInt64,
        wiredBytes: UInt64,
        compressedBytes: UInt64,
        swapUsedBytes: UInt64,
        pressure: String,
        history: [Double]
    ) {
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.freeBytes = freeBytes
        self.wiredBytes = wiredBytes
        self.compressedBytes = compressedBytes
        self.swapUsedBytes = swapUsedBytes
        self.pressure = pressure
        self.history = history
    }

    public var totalBytes: UInt64
    public var usedBytes: UInt64
    public var freeBytes: UInt64
    public var wiredBytes: UInt64
    public var compressedBytes: UInt64
    public var swapUsedBytes: UInt64
    public var pressure: String
    public var history: [Double]

    public var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }
}

public struct DiskSnapshot: Sendable, Equatable {
    public var volumeName: String
    public var totalBytes: Int64
    public var usedBytes: Int64
    public var freeBytes: Int64

    public var usedPercent: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes) * 100
    }
}

public struct TemperatureSnapshot: Sendable, Equatable {
    public var cpuCelsius: Double?
    public var unavailableReasonKey: String?

    public var isAvailable: Bool { cpuCelsius != nil }
}

public struct ProcessUsage: Identifiable, Sendable, Equatable {
    public var id: Int32
    public var name: String
    public var cpuPercent: Double
    public var memoryBytes: Int64
}

public struct NetworkSnapshot: Sendable, Equatable {
    public var interfaceName: String
    public var bytesInPerSec: Double
    public var bytesOutPerSec: Double
}

public struct PowerSnapshot: Sendable, Equatable {
    public var isOnBattery: Bool
    public var levelPercent: Double?
    public var timeRemaining: String?
}

public struct MonitorDashboard: Sendable, Equatable {
    public var cpu: CPUSnapshot
    public var memory: MemorySnapshot
    public var disk: DiskSnapshot
    public var temperature: TemperatureSnapshot
    public var network: NetworkSnapshot
    public var power: PowerSnapshot
    public var topProcesses: [ProcessUsage]
    public var uptime: TimeInterval
}
