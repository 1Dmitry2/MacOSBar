import Darwin
import Foundation
import IOKit
import IOKit.ps
import Observation

@Observable
public final class SystemMonitorService: @unchecked Sendable {
    public static let shared = SystemMonitorService()

    public private(set) var dashboard: MonitorDashboard
    public var updateInterval: TimeInterval = 2.0
    public var isRunning: Bool { timer != nil }

    private var timer: Timer?
    private var lastCPUInfo: host_cpu_load_info?
    private var cpuHistory: [Double] = []
    private var memHistory: [Double] = []
    private let historyLimit = 60
    private var lastNetworkBytes: (in: UInt64, out: UInt64)?
    private var lastNetworkDate: Date?
    private var lastProcessTimes: [Int32: (user: UInt64, system: UInt64, at: Date)] = [:]

    private init() {
        dashboard = MonitorDashboard(
            cpu: CPUSnapshot(totalUsage: 0, userUsage: 0, systemUsage: 0, coreCount: ProcessInfo.processInfo.processorCount, history: []),
            memory: MemorySnapshot(totalBytes: 0, usedBytes: 0, freeBytes: 0, wiredBytes: 0, compressedBytes: 0, swapUsedBytes: 0, pressure: "—", history: []),
            disk: DiskSnapshot(volumeName: "—", totalBytes: 0, usedBytes: 0, freeBytes: 0),
            temperature: TemperatureSnapshot(cpuCelsius: nil),
            network: NetworkSnapshot(interfaceName: "—", bytesInPerSec: 0, bytesOutPerSec: 0),
            power: PowerSnapshot(isOnBattery: false, levelPercent: nil, timeRemaining: nil),
            topProcesses: [],
            uptime: 0
        )
        refresh()
    }

    public func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    public func refresh() {
        let cpu = readCPU()
        let mem = readMemory()
        let disk = readDisk()
        let net = readNetwork()
        let power = readPower()
        dashboard = MonitorDashboard(
            cpu: cpu,
            memory: mem,
            disk: disk,
            temperature: makeTemperatureSnapshot(),
            network: net,
            power: power,
            topProcesses: readTopProcesses(limit: 10),
            uptime: ProcessInfo.processInfo.systemUptime
        )
    }

    private func readCPU() -> CPUSnapshot {
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        var load = host_cpu_load_info()
        let result = withUnsafeMutablePointer(to: &load) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        guard result == KERN_SUCCESS else {
            return dashboard.cpu
        }

        var total: Double = 0
        var user: Double = 0
        var system: Double = 0

        if let last = lastCPUInfo {
            let userDiff = Double(load.cpu_ticks.0 - last.cpu_ticks.0)
            let sysDiff = Double(load.cpu_ticks.1 - last.cpu_ticks.1)
            let idleDiff = Double(load.cpu_ticks.2 - last.cpu_ticks.2)
            let niceDiff = Double(load.cpu_ticks.3 - last.cpu_ticks.3)
            let sum = userDiff + sysDiff + idleDiff + niceDiff
            if sum > 0 {
                user = (userDiff + niceDiff) / sum * 100
                system = sysDiff / sum * 100
                total = (userDiff + sysDiff + niceDiff) / sum * 100
            }
        }
        lastCPUInfo = load

        cpuHistory.append(total)
        if cpuHistory.count > historyLimit { cpuHistory.removeFirst() }

        return CPUSnapshot(
            totalUsage: total,
            userUsage: user,
            systemUsage: system,
            coreCount: ProcessInfo.processInfo.processorCount,
            history: cpuHistory
        )
    }

    private func readMemory() -> MemorySnapshot {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        let pageSize = UInt64(getpagesize())
        let total = ProcessInfo.processInfo.physicalMemory

        guard result == KERN_SUCCESS else {
            return dashboard.memory
        }

        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let used = active + wired + compressed
        let free = total > used ? total - used : 0

        let fraction = total > 0 ? Double(used) / Double(total) * 100 : 0
        memHistory.append(fraction)
        if memHistory.count > historyLimit { memHistory.removeFirst() }

        let pressure: String
        if fraction > 90 { pressure = "Critical" }
        else if fraction > 75 { pressure = "Warning" }
        else { pressure = "Normal" }

        return MemorySnapshot(
            totalBytes: total,
            usedBytes: used,
            freeBytes: free,
            wiredBytes: wired,
            compressedBytes: compressed,
            swapUsedBytes: readSwapUsedBytes(),
            pressure: pressure,
            history: memHistory
        )
    }

    private func readDisk() -> DiskSnapshot {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        guard
            let values = try? url.resourceValues(forKeys: [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey]),
            let total = values.volumeTotalCapacity,
            let free = values.volumeAvailableCapacity
        else {
            return dashboard.disk
        }
        let used = Int64(total) - Int64(free)
        return DiskSnapshot(
            volumeName: values.volumeName ?? "Macintosh HD",
            totalBytes: Int64(total),
            usedBytes: used,
            freeBytes: Int64(free)
        )
    }

    private func readNetwork() -> NetworkSnapshot {
        var inBytes: UInt64 = 0
        var outBytes: UInt64 = 0
        var primaryName = "en0"

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else {
            return dashboard.network
        }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let name = String(cString: ptr.pointee.ifa_name)
            guard name.hasPrefix("en") || name == "awdl0" else { continue }
            if let data = ptr.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) {
                inBytes += UInt64(data.pointee.ifi_ibytes)
                outBytes += UInt64(data.pointee.ifi_obytes)
                if name.hasPrefix("en") { primaryName = name }
            }
        }

        let now = Date()
        var inRate: Double = 0
        var outRate: Double = 0
        if let last = lastNetworkBytes, let lastDate = lastNetworkDate {
            let dt = now.timeIntervalSince(lastDate)
            if dt > 0 {
                inRate = Double(inBytes &- last.in) / dt
                outRate = Double(outBytes &- last.out) / dt
            }
        }
        lastNetworkBytes = (inBytes, outBytes)
        lastNetworkDate = now

        return NetworkSnapshot(interfaceName: primaryName, bytesInPerSec: inRate, bytesOutPerSec: outRate)
    }

    private func readPower() -> PowerSnapshot {
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] ?? []
        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else { continue }
            let isAC = (info[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
            let current = info[kIOPSCurrentCapacityKey] as? Double
            let time = info[kIOPSTimeToEmptyKey] as? Int
            let timeStr: String?
            if let t = time, t > 0 { timeStr = "\(t / 60)h \(t % 60)m" } else { timeStr = nil }
            return PowerSnapshot(isOnBattery: !isAC, levelPercent: current, timeRemaining: timeStr)
        }
        return PowerSnapshot(isOnBattery: false, levelPercent: nil, timeRemaining: nil)
    }

    private func readTopProcesses(limit: Int) -> [ProcessUsage] {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size = 0
        guard sysctl(&mib, u_int(mib.count), nil, &size, nil, 0) == 0, size > 0 else { return [] }

        let count = size / MemoryLayout<kinfo_proc>.size
        var procs = [kinfo_proc](repeating: kinfo_proc(), count: count)
        guard sysctl(&mib, u_int(mib.count), &procs, &size, nil, 0) == 0 else { return [] }

        var results: [ProcessUsage] = []
        for p in procs {
            let pid = p.kp_proc.p_pid
            guard pid > 0 else { continue }
            let name = withUnsafePointer(to: p.kp_proc.p_comm) { ptr -> String in
                String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
            }
            var taskInfo = proc_taskinfo()
            let len = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, Int32(MemoryLayout<proc_taskinfo>.size))
            let mem = len > 0 ? Int64(taskInfo.pti_resident_size) : 0
            let cpu = len > 0 ? cpuPercent(pid: pid, taskInfo: taskInfo) : 0
            results.append(ProcessUsage(id: pid, name: name, cpuPercent: cpu, memoryBytes: mem))
        }
        return results.sorted { lhs, rhs in
            if lhs.cpuPercent == rhs.cpuPercent { return lhs.memoryBytes > rhs.memoryBytes }
            return lhs.cpuPercent > rhs.cpuPercent
        }.prefix(limit).map { $0 }
    }

    private func makeTemperatureSnapshot() -> TemperatureSnapshot {
        let probe = TemperatureProbe.current()
        return TemperatureSnapshot(cpuCelsius: probe.celsius, unavailableReasonKey: probe.celsius == nil ? probe.unavailableReasonKey : nil)
    }

    private func readSwapUsedBytes() -> UInt64 {
        var swap = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        var name: [Int32] = [CTL_VM, VM_SWAPUSAGE]
        guard sysctl(&name, 2, &swap, &size, nil, 0) == 0 else { return 0 }
        return UInt64(swap.xsu_used)
    }

    private func cpuPercent(pid: Int32, taskInfo: proc_taskinfo) -> Double {
        let user = taskInfo.pti_total_user
        let system = taskInfo.pti_total_system
        let now = Date()
        defer { lastProcessTimes[pid] = (user, system, now) }
        guard let last = lastProcessTimes[pid] else { return 0 }
        let dt = now.timeIntervalSince(last.at)
        guard dt > 0.05 else { return 0 }
        let delta = Double((user &- last.user) &+ (system &- last.system))
        let usage = (delta / (dt * 1_000_000_000)) * 100
        return min(max(usage, 0), 100 * Double(ProcessInfo.processInfo.processorCount))
    }
}
