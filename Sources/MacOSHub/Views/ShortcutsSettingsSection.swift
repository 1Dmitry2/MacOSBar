import AppKit
import Carbon
import HubCore
import HubSettings
import HubShortcuts
import SwiftUI

struct ShortcutsSettingsSection: View {
    @Environment(\.locale) private var locale
    @State private var bindings = GlobalShortcutManager.shared.allBindings()
    @State private var recording: ShortcutAction?
    @State private var keyMonitor: Any?
    @State private var errorMessage: String?

    var body: some View {
        Section {
            ForEach(bindings, id: \.action) { binding in
                HStack {
                    Text(L10n.tr(binding.action.localizationKey, locale: locale))
                    Spacer()
                    Text(shortcutLabel(binding))
                        .font(.caption.monospaced())
                    Button(L10n.tr("shortcut.change", locale: locale)) {
                        recording = binding.action
                        startRecording()
                    }
                    Button(L10n.tr("shortcut.reset", locale: locale)) {
                        GlobalShortcutManager.shared.reset(binding.action)
                        reload()
                    }
                }
            }
            if let recording {
                Text(L10n.tr("shortcut.recording", locale: locale) + ": \(L10n.tr(recording.localizationKey, locale: locale))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(L10n.tr("action.cancel", locale: locale)) { cancelRecording() }
            }
            if let errorMessage {
                Text(errorMessage).font(.caption).foregroundStyle(.red)
            }
        } header: {
            LText("settings.shortcuts")
        }
        .onAppear { reload() }
    }

    private func reload() {
        bindings = GlobalShortcutManager.shared.allBindings()
    }

    private func shortcutLabel(_ binding: ShortcutBinding) -> String {
        let mod = KeyCodeFormatter.modifiers(binding.modifiers)
        let key = KeyCodeFormatter.key(binding.keyCode)
        return "\(mod)\(key)"
    }

    private func startRecording() {
        cancelRecording()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            guard let action = recording else { return event }
            if event.type == .keyDown {
                let binding = ShortcutBinding(action: action, keyCode: UInt32(event.keyCode), modifiers: UInt32(event.modifierFlags.carbonFlags), isEnabled: true)
                let conflicts = GlobalShortcutManager.shared.conflicts(with: binding)
                if !conflicts.isEmpty {
                    errorMessage = L10n.tr("shortcut.conflict", locale: locale)
                } else {
                    GlobalShortcutManager.shared.update(binding)
                    errorMessage = nil
                    recording = nil
                    cancelRecording()
                    reload()
                }
                return nil
            }
            return event
        }
    }

    private func cancelRecording() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
        keyMonitor = nil
        recording = nil
    }
}

enum KeyCodeFormatter {
    static func modifiers(_ raw: UInt32) -> String {
        var parts: [String] = []
        if raw & UInt32(cmdKey) != 0 { parts.append("⌘") }
        if raw & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if raw & UInt32(optionKey) != 0 { parts.append("⌥") }
        if raw & UInt32(controlKey) != 0 { parts.append("⌃") }
        return parts.joined()
    }

    static func key(_ code: UInt32) -> String {
        switch Int32(code) {
        case Int32(kVK_ANSI_A): return "A"
        case Int32(kVK_ANSI_C): return "C"
        case Int32(kVK_ANSI_D): return "D"
        case Int32(kVK_ANSI_I): return "I"
        case Int32(kVK_ANSI_K): return "K"
        case Int32(kVK_ANSI_M): return "M"
        case Int32(kVK_ANSI_S): return "S"
        default: return "#\(code)"
        }
    }
}

private extension NSEvent.ModifierFlags {
    var carbonFlags: UInt32 {
        var value: UInt32 = 0
        if contains(.command) { value |= UInt32(cmdKey) }
        if contains(.shift) { value |= UInt32(shiftKey) }
        if contains(.option) { value |= UInt32(optionKey) }
        if contains(.control) { value |= UInt32(controlKey) }
        return value
    }
}
