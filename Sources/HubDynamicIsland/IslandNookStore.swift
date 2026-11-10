import Foundation
import HubDiagnostics
import Observation

@MainActor
@Observable
public final class IslandNookStore {
    public static let shared = IslandNookStore()

    public var selectedSection: IslandNookSection {
        didSet { defaults.set(selectedSection.rawValue, forKey: Keys.section) }
    }

    public var focusMode: IslandFocusMode {
        didSet { defaults.set(focusMode.rawValue, forKey: Keys.focusMode) }
    }

    /// Planned focus / break length in minutes (before start).
    public var focusDurationMinutes: Int {
        didSet { defaults.set(focusDurationMinutes, forKey: Keys.focusMinutes) }
    }

  /// Seconds left when a session is running; `nil` when idle.
    public private(set) var focusRemainingSeconds: Int?
    public private(set) var focusRunning = false

    public var tasks: [IslandNookTask] {
        didSet { persistTasks() }
    }

    public private(set) var cpuSparkline: [Double] = []
    public private(set) var ramSparkline: [Double] = []

    private let defaults = UserDefaults.standard
    private let log = HubLogger.log(.island)
    private var focusTask: Task<Void, Never>?
    public private(set) var focusSessionTotalSeconds: Int = 0
    private let sparklineCapacity = 24

    private enum Keys {
        static let section = "island.nook.section"
        static let focusMode = "island.nook.focusMode"
        static let focusMinutes = "island.nook.focusMinutes"
        static let tasks = "island.nook.tasks"
    }

    private init() {
        let rawSection = defaults.string(forKey: Keys.section) ?? IslandNookSection.monitor.rawValue
        let parsed = IslandNookSection(rawValue: rawSection) ?? .monitor
        selectedSection = parsed == .tasks ? .monitor : parsed
        let rawFocus = defaults.string(forKey: Keys.focusMode) ?? IslandFocusMode.concentration.rawValue
        focusMode = IslandFocusMode(rawValue: rawFocus) ?? .concentration
        let minutes = defaults.integer(forKey: Keys.focusMinutes)
        focusDurationMinutes = minutes > 0 ? minutes : 25
        if let data = defaults.data(forKey: Keys.tasks),
           let decoded = try? JSONDecoder().decode([IslandNookTask].self, from: data) {
            tasks = decoded
        } else {
            tasks = []
        }
    }

    public func selectSection(_ section: IslandNookSection) {
        selectedSection = section
    }

    public func addTask(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.append(IslandNookTask(title: trimmed))
    }

    public func toggleTask(_ id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isDone.toggle()
    }

    public func removeTask(_ id: UUID) {
        tasks.removeAll { $0.id == id }
    }

    public func toggleFocusTimer() {
        if focusRunning {
            stopFocusTimer()
        } else {
            startFocusTimer()
        }
    }

    public func startFocusTimer() {
        focusTask?.cancel()
        let total = max(60, focusDurationMinutes * 60)
        focusSessionTotalSeconds = total
        focusRemainingSeconds = total
        focusRunning = true
        focusTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, self.focusRunning else { break }
                self.focusTick()
            }
        }
        log.info("Focus timer started (\(self.focusDurationMinutes)m)")
    }

    public func stopFocusTimer() {
        focusTask?.cancel()
        focusTask = nil
        focusRunning = false
        focusRemainingSeconds = nil
        focusSessionTotalSeconds = 0
    }

    public func recordMetricSamples(cpu: Double, ramFraction: Double) {
        cpuSparkline.append(cpu)
        ramSparkline.append(ramFraction * 100)
        if cpuSparkline.count > sparklineCapacity {
            cpuSparkline.removeFirst(cpuSparkline.count - sparklineCapacity)
        }
        if ramSparkline.count > sparklineCapacity {
            ramSparkline.removeFirst(ramSparkline.count - sparklineCapacity)
        }
    }

    private func focusTick() {
        guard var remaining = focusRemainingSeconds else {
            stopFocusTimer()
            return
        }
        remaining -= 1
        if remaining <= 0 {
            focusRemainingSeconds = 0
            stopFocusTimer()
            focusMode = focusMode == .concentration ? .breakTime : .concentration
        } else {
            focusRemainingSeconds = remaining
        }
    }

    private func persistTasks() {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        defaults.set(data, forKey: Keys.tasks)
    }
}

public struct IslandNookTask: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var isDone: Bool

    public init(id: UUID = UUID(), title: String, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}
