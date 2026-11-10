import CoreAudio
import Foundation
import HubSettings

@MainActor
final class MicrophoneActivityProvider {
    private var pollTimer: Timer?
    private var lastActive = false
    var onChange: ((IslandActivity?) -> Void)?

    func start() {
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.evaluate() }
        }
        evaluate()
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        lastActive = false
        onChange?(nil)
    }

    private func evaluate() {
        guard AppConfiguration.shared.islandEventMicrophoneEnabled else {
            if lastActive { onChange?(nil) }
            lastActive = false
            return
        }
        let active = inputDeviceIsRunning()
        guard active != lastActive else {
            if active { onChange?(activeActivity()) }
            return
        }
        lastActive = active
        onChange?(active ? activeActivity() : nil)
    }

    private func activeActivity() -> IslandActivity {
        IslandActivity(
            id: "microphone.active",
            kind: .microphone,
            title: "Microphone in use",
            subtitle: "Default input active",
            systemImage: "mic.fill"
        )
    }

    private func inputDeviceIsRunning() -> Bool {
        guard let deviceID = defaultInputDeviceID() else { return false }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var running: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &running)
        guard status == noErr else { return false }
        return running != 0
    }

    private func defaultInputDeviceID() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        guard status == noErr, deviceID != 0 else { return nil }
        return deviceID
    }
}
