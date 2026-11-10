import Foundation
import HubDiagnostics

/// Streams Now Playing via bundled mediaremote-adapter (same stack as DynamicNotch).
final class IslandMediaRemoteStream: @unchecked Sendable {
    struct Update: Sendable, Equatable {
        var title: String?
        var artist: String?
        var album: String?
        var isPlaying: Bool
        var artworkData: Data?
    }

    var onUpdate: (@Sendable (Update?) -> Void)?

    private let log = HubLogger.log(.island)
    private let queue = DispatchQueue(label: "MacOSHub.mediaremote.stream", qos: .utility)
    private var process: Process?
    private var buffer = ""
    private var running = false

    func start() {
        queue.async { [self] in
            guard !running else { return }
            running = true
            launch()
        }
    }

    func stop() {
        queue.async { [self] in
            running = false
            terminateProcess()
            onUpdate?(nil)
        }
    }

    private func launch() {
        guard running, let resources = IslandMediaRemoteAdapterResources.resolve() else {
            log.debug("MediaRemote adapter resources missing; using in-process fallback only")
            return
        }

        let command = resources.streamArguments()
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: command[0])
        process.arguments = Array(command.dropFirst())
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        process.terminationHandler = { [weak self] _ in
            self?.queue.async {
                guard let self, self.running else { return }
                self.process = nil
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    self?.queue.async { [weak self] in self?.launch() }
                }
            }
        }

        do {
            try process.run()
        } catch {
            log.info("MediaRemote adapter launch failed: \(error.localizedDescription)")
            return
        }
        self.process = process
        buffer = ""
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            self?.queue.async { [weak self] in self?.consume(data) }
        }
    }

    private func terminateProcess() {
        process?.terminationHandler = nil
        if let process, process.isRunning { process.terminate() }
        process = nil
        buffer = ""
    }

    private func consume(_ data: Data) {
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        buffer.append(chunk)
        while let breakIndex = buffer.firstIndex(of: "\n") {
            let line = String(buffer[..<breakIndex])
            buffer.removeSubrange(...breakIndex)
            parse(line: line)
        }
    }

    private struct StreamMessage: Decodable {
        var type: String?
        var payload: Payload?
    }

    private struct Payload: Decodable {
        var playing: Bool?
        var title: String?
        var artist: String?
        var album: String?
        var bundleIdentifier: String?
        var artworkData: String?
        var artworkMimeType: String?
    }

    private func parse(line: String) {
        guard let data = line.data(using: .utf8) else { return }
        guard let message = try? JSONDecoder().decode(StreamMessage.self, from: data) else { return }
        guard message.type == nil || message.type == "data" else { return }

        guard let payload = message.payload else { return }

        let playing = payload.playing ?? false
        let title = payload.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = payload.artist?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard playing || !(title?.isEmpty ?? true) else { return }

        let resolvedTitle: String? = {
            if let title, !title.isEmpty { return title }
            if playing { return payload.bundleIdentifier ?? "Now Playing" }
            return nil
        }()

        let artwork: Data? = {
            guard let raw = payload.artworkData, !raw.isEmpty else { return nil }
            return Data(base64Encoded: raw, options: .ignoreUnknownCharacters)
        }()

        onUpdate?(
            Update(
                title: resolvedTitle,
                artist: artist?.isEmpty == true ? nil : artist,
                album: payload.album?.trimmingCharacters(in: .whitespacesAndNewlines),
                isPlaying: playing,
                artworkData: artwork
            )
        )
    }
}
