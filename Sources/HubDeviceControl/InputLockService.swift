import AppKit
import ApplicationServices
import Foundation
import HubDiagnostics
import HubPermissions
import HubSettings
import Observation

public enum InputLockMode: Sendable, Equatable, Identifiable {
    case none
    case keyboard
    case trackpad

    public var id: String {
        switch self {
        case .none: return "none"
        case .keyboard: return "keyboard"
        case .trackpad: return "trackpad"
        }
    }
}

public enum InputLockState: Sendable, Equatable {
    case idle
    case active(mode: InputLockMode, expiresAt: Date?)
    case permissionRequired
    case unavailable(reason: String)
}

@Observable
public final class InputLockService: @unchecked Sendable {
    public static let shared = InputLockService()

    public private(set) var state: InputLockState = .idle
    public var keyboardLocked: Bool = false
    public var trackpadLocked: Bool = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var autoUnlockTimer: Timer?
    private var emergencyMonitorTimer: Timer?
    private var commandPressTimes: [Date] = []
    private let log = HubLogger.log(.device)
    private let permissions = PermissionManager()

    private init() {}

    public var limitationNotice: String {
        "macOS does not expose independent built-in keyboard vs trackpad disable. This module filters keyboard or pointer events system-wide via a trusted event tap. External USB/BT devices may behave differently."
    }

    public func requestPermissions() {
        permissions.requestIfNeeded(.accessibility)
        permissions.requestIfNeeded(.inputMonitoring)
    }

    public func setKeyboardLock(_ enabled: Bool) {
        keyboardLocked = enabled
        if enabled { trackpadLocked = false }
        reconcile()
    }

    public func setTrackpadLock(_ enabled: Bool) {
        trackpadLocked = enabled
        if enabled { keyboardLocked = false }
        reconcile()
    }

    public func unlockAll() {
        keyboardLocked = false
        trackpadLocked = false
        stopTap()
        autoUnlockTimer?.invalidate()
        state = .idle
    }

    private func reconcile() {
        if keyboardLocked {
            activate(mode: .keyboard)
        } else if trackpadLocked {
            activate(mode: .trackpad)
        } else {
            unlockAll()
        }
    }

    private func activate(mode: InputLockMode) {
        guard permissions.status(for: .accessibility) == .granted else {
            state = .permissionRequired
            requestPermissions()
            return
        }
        startTap(mode: mode)
        scheduleAutoUnlock()
        startEmergencyMonitor()
        let seconds = AppConfiguration.shared.deviceAutoUnlockSeconds
        let expires = seconds > 0 ? Date().addingTimeInterval(TimeInterval(seconds)) : nil
        state = .active(mode: mode, expiresAt: expires)
    }

    private func scheduleAutoUnlock() {
        autoUnlockTimer?.invalidate()
        let seconds = AppConfiguration.shared.deviceAutoUnlockSeconds
        guard seconds > 0 else { return }
        autoUnlockTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: false) { [weak self] _ in
            self?.unlockAll()
        }
    }

    private func startEmergencyMonitor() {
        emergencyMonitorTimer?.invalidate()
        emergencyMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.pollEmergencyCombo()
        }
    }

    private func pollEmergencyCombo() {
        let flags = NSEvent.modifierFlags
        if flags.contains([.command, .deviceIndependentFlagsMask]) {
            let bothCommand = flags.contains(.command)
            if bothCommand {
                commandPressTimes.append(Date())
                commandPressTimes = commandPressTimes.filter { Date().timeIntervalSince($0) < 3.5 }
            }
        }
        if commandPressTimes.count >= 2 {
            let span = commandPressTimes.last!.timeIntervalSince(commandPressTimes.first!)
            if span >= 2.8 && span <= 3.5 {
                unlockAll()
                commandPressTimes.removeAll()
            }
        }
    }

    private func startTap(mode: InputLockMode) {
        stopTap()
        let mask: CGEventMask
        switch mode {
        case .keyboard:
            mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        case .trackpad, .none:
            mask = (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.leftMouseUp.rawValue)
                | (1 << CGEventType.rightMouseDown.rawValue) | (1 << CGEventType.rightMouseUp.rawValue)
                | (1 << CGEventType.scrollWheel.rawValue) | (1 << CGEventType.mouseMoved.rawValue)
        }
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let service = Unmanaged<InputLockService>.fromOpaque(refcon).takeUnretainedValue()
            return service.handleEvent(proxy: proxy, type: type, event: event)
        }
        let ref = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: ref
        ) else {
            state = .unavailable(reason: "Could not create event tap. Grant Accessibility and Input Monitoring.")
            return
        }
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        if keyboardLocked {
            if type == .keyDown || type == .keyUp || type == .flagsChanged {
                return nil
            }
        }
        if trackpadLocked {
            switch type {
            case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .scrollWheel, .mouseMoved:
                return nil
            default:
                break
            }
        }
        return Unmanaged.passUnretained(event)
    }

    private func stopTap() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source = runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes) }
        eventTap = nil
        runLoopSource = nil
        emergencyMonitorTimer?.invalidate()
    }

    deinit {
        unlockAll()
    }
}
