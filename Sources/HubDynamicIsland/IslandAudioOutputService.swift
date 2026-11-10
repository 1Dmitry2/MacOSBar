import CoreAudio
import Foundation
import Observation

public struct AudioOutputDevice: Identifiable, Equatable, Sendable {
    public let id: UInt32
    public let name: String
    public let isBuiltIn: Bool

    public var systemImage: String {
        if isBuiltIn { return "macbook" }
        let lower = name.lowercased()
        if lower.contains("airpods") || lower.contains("headphone") { return "headphones" }
        return "speaker.wave.2.fill"
    }
}

@MainActor
@Observable
public final class IslandAudioOutputService {
    public static let shared = IslandAudioOutputService()

    public private(set) var devices: [AudioOutputDevice] = []
    public private(set) var defaultDeviceID: UInt32?

    private init() {
        refresh()
    }

    public func refresh() {
        devices = enumerateOutputDevices()
        defaultDeviceID = readDefaultOutputDeviceID()
    }

    public func setDefaultOutput(_ deviceID: UInt32) {
        var mutable = deviceID
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &mutable
        )
        guard status == noErr else { return }
        defaultDeviceID = deviceID
        refresh()
    }

    private func readDefaultOutputDeviceID() -> UInt32? {
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

    private func enumerateOutputDevices() -> [AudioOutputDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize) == noErr else {
            return []
        }
        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &ids) == noErr else {
            return []
        }
        return ids.compactMap { deviceInfo($0) }
    }

    private func deviceInfo(_ id: AudioDeviceID) -> AudioOutputDevice? {
        guard hasOutputStreams(id), let name = deviceName(id) else { return nil }
        return AudioOutputDevice(id: id, name: name, isBuiltIn: isBuiltInTransport(id))
    }

    private func hasOutputStreams(_ id: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &address, 0, nil, &dataSize) == noErr else { return false }
        return dataSize > 0
    }

    private func deviceName(_ id: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var name: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &name) == noErr else { return nil }
        return name as String
    }

    private func isBuiltInTransport(_ id: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var transport: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &transport) == noErr else { return false }
        return transport == kAudioDeviceTransportTypeBuiltIn
    }
}
