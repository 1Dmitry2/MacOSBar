import Combine
import Foundation

public final class IslandClock: ObservableObject {
    @Published public var timeString = ""
    @Published public var dateString = ""
    private var timer: Timer?

    public init(live: Bool = true) {
        tick()
        guard live else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
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
