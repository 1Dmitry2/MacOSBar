import AppKit
import Carbon
import Foundation
import HubCore
import HubSettings
import Observation

public enum ShortcutAction: String, CaseIterable, Codable, Sendable, Identifiable {
    case toggleApp
    case openSmartCleaner
    case startCleanerScan
    case openSystemMonitor
    case toggleMonitorSidebar
    case toggleDynamicIsland
    case toggleIslandExpanded
    case openDeviceControl

    public var id: String { rawValue }

    public var localizationKey: String { "shortcut.\(rawValue)" }

    public var defaultModifiers: UInt32 {
        switch self {
        case .toggleApp: return UInt32(cmdKey | shiftKey)
        case .openSmartCleaner: return UInt32(cmdKey | shiftKey)
        case .startCleanerScan: return UInt32(cmdKey | optionKey)
        case .openSystemMonitor: return UInt32(cmdKey | shiftKey)
        case .toggleMonitorSidebar: return UInt32(controlKey | optionKey)
        case .toggleDynamicIsland: return UInt32(controlKey | cmdKey)
        case .toggleIslandExpanded: return UInt32(controlKey | shiftKey)
        case .openDeviceControl: return UInt32(cmdKey | shiftKey)
        }
    }

    public var defaultKeyCode: UInt32 {
        switch self {
        case .toggleApp: return UInt32(kVK_ANSI_M)
        case .openSmartCleaner: return UInt32(kVK_ANSI_C)
        case .startCleanerScan: return UInt32(kVK_ANSI_S)
        case .openSystemMonitor: return UInt32(kVK_ANSI_M)
        case .toggleMonitorSidebar: return UInt32(kVK_ANSI_S)
        case .toggleDynamicIsland: return UInt32(kVK_ANSI_D)
        case .toggleIslandExpanded: return UInt32(kVK_ANSI_I)
        case .openDeviceControl: return UInt32(kVK_ANSI_K)
        }
    }
}

public struct ShortcutBinding: Codable, Sendable, Equatable {
    public var action: ShortcutAction
    public var keyCode: UInt32
    public var modifiers: UInt32
    public var isEnabled: Bool

    public init(action: ShortcutAction, keyCode: UInt32, modifiers: UInt32, isEnabled: Bool = true) {
        self.action = action
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isEnabled = isEnabled
    }
}

public extension Notification.Name {
    static let hubShortcutTriggered = Notification.Name("hub.shortcut.triggered")
}

@MainActor
public final class GlobalShortcutManager: NSObject {
    public static let shared = GlobalShortcutManager()

    private var bindings: [ShortcutAction: ShortcutBinding] = [:]
    private var hotKeyRefs: [ShortcutAction: EventHotKeyRef] = [:]
    private var handlerInstalled = false

    private override init() {
        super.init()
        loadBindings()
        installHandlerIfNeeded()
        registerAll()
    }

    public func binding(for action: ShortcutAction) -> ShortcutBinding {
        bindings[action] ?? ShortcutBinding(
            action: action,
            keyCode: action.defaultKeyCode,
            modifiers: action.defaultModifiers
        )
    }

    public func allBindings() -> [ShortcutBinding] {
        ShortcutAction.allCases.map { binding(for: $0) }
    }

    public func update(_ binding: ShortcutBinding) {
        bindings[binding.action] = binding
        persist()
        registerAll()
    }

    public func reset(_ action: ShortcutAction) {
        bindings[action] = ShortcutBinding(
            action: action,
            keyCode: action.defaultKeyCode,
            modifiers: action.defaultModifiers
        )
        persist()
        registerAll()
    }

    public func conflicts(with binding: ShortcutBinding) -> [ShortcutAction] {
        bindings.compactMap { action, existing in
            guard existing.isEnabled, binding.isEnabled, action != binding.action else { return nil }
            guard existing.keyCode == binding.keyCode, existing.modifiers == binding.modifiers else { return nil }
            return action
        }
    }

    private func loadBindings() {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: "hub.shortcuts") else {
            for action in ShortcutAction.allCases {
                bindings[action] = ShortcutBinding(
                    action: action,
                    keyCode: action.defaultKeyCode,
                    modifiers: action.defaultModifiers
                )
            }
            return
        }
        if let decoded = try? JSONDecoder().decode([ShortcutBinding].self, from: data) {
            for item in decoded { bindings[item.action] = item }
        }
        for action in ShortcutAction.allCases where bindings[action] == nil {
            bindings[action] = ShortcutBinding(
                action: action,
                keyCode: action.defaultKeyCode,
                modifiers: action.defaultModifiers
            )
        }
    }

    private func persist() {
        let list = ShortcutAction.allCases.compactMap { bindings[$0] }
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: "hub.shortcuts")
        }
    }

    private func registerAll() {
        unregisterAll()
        for action in ShortcutAction.allCases {
            guard let binding = bindings[action], binding.isEnabled else { continue }
            var ref: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: OSType(0x4D4F5348), id: UInt32(actionIndex(action)))
            let status = RegisterEventHotKey(
                binding.keyCode,
                binding.modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &ref
            )
            if status == noErr, let ref {
                hotKeyRefs[action] = ref
            }
        }
    }

    private func unregisterAll() {
        for ref in hotKeyRefs.values {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
    }

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                _ = Unmanaged<GlobalShortcutManager>.fromOpaque(userData).takeUnretainedValue()
                var hotID = EventHotKeyID()
                GetEventParameter(
                    event,
                    UInt32(kEventParamDirectObject),
                    UInt32(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotID
                )
                let idx = Int(hotID.id)
                guard let action = ShortcutAction.allCases[safe: idx] else { return noErr }
                NotificationCenter.default.post(name: .hubShortcutTriggered, object: action)
                return noErr
            },
            1,
            &spec,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )
    }

    private func actionIndex(_ action: ShortcutAction) -> Int {
        ShortcutAction.allCases.firstIndex(of: action) ?? 0
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
