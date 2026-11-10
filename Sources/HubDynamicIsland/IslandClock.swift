import Combine
import Foundation

@MainActor
public final class IslandClock: ObservableObject {
    @Published public var timeString = ""
    @Published public var dateString = ""
    private var tickTask: Task<Void, Never>?

    public init(live: Bool = true) {
        tick()
        guard live else { return }
        tickTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.tick()
            }
        }
    }

    deinit {
        tickTask?.cancel()
    }

    private func tick() {
        let now = Date()
        let time = DateFormatter()
        time.dateFormat = "HH:mm"
        let date = DateFormatter()
        date.dateStyle = .medium
        date.timeStyle = .none
        timeString = time.string(from: now)
        dateString = date.string(from: now)
    }
}
