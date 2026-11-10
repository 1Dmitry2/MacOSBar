import CoreAudio
import Foundation
import HubSettings

@MainActor
final class AudioDeviceActivityProvider {
    private var pollTimer: Timer?
    private var lastDeviceID: AudioDeviceID?
    var onChange: ((IslandActivity?) -> Void)?

    func start() {
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.evaluate() }
        }
        evaluate()
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        lastDeviceID = nil
        onChange?(nil)
    }

    private func evaluate() {
        guard AppConfiguration.shared.islandEventAudioDeviceEnabled else {
            onChange?(nil)
            return
        }
        guard let deviceID = defaultOutputDeviceID() else {
            onChange?(nil)
            return
        }
        if let previous = lastDeviceID, previous != deviceID {
            let name = deviceName(deviceID) ?? "Audio device"
            DynamicIslandStateManager.shared.showTransient(
                IslandActivity(
                    id: UUID().uuidString,
                    kind: .audioDevice,
                    title: "\(name) connected",
                    systemImage: "headphones",
                    isPersistent: false
                )
            )
            IslandStateManager.shared.enqueueNotification(.headphones)
        }
        lastDeviceID = deviceID
        let name = deviceName(deviceID) ?? "Audio output"
        onChange?(
            IslandActivity(
                id: "audio.output.\(deviceID)",
                kind: .audioDevice,
                title: name,
                subtitle: transportDescription(deviceID),
                systemImage: systemImage(for: name)
            )
        )
    }

    private func defaultOutputDeviceID() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
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

    private func deviceName(_ id: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var name: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &name)
        guard status == noErr else { return nil }
        return name as String
    }

    private func transportDescription(_ id: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var transport: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &transport)
        guard status == noErr else { return nil }
        switch transport {
        case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE:
            return "Bluetooth"
        case kAudioDeviceTransportTypeBuiltIn:
            return "Built-in"
        case kAudioDeviceTransportTypeUSB:
            return "USB"
        default:
            return nil
        }
    }

    private func systemImage(for name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("airpods") || lower.contains("headphone") { return "headphones" }
        return "speaker.wave.2.fill"
    }
}
