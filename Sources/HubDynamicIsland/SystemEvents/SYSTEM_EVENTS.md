# Dynamic Island — system events

## Layout

```
SystemEventManager (starts with DynamicIslandController)
├── MicrophoneActivityProvider   → DynamicIslandStateManager (persistent)
├── CameraActivityProvider       → DynamicIslandStateManager (persistent)
├── AudioDeviceActivityProvider  → persistent + transient route banners
├── MediaActivityProvider        → persistent + IslandStateManager.showLiveActivity
└── NotificationActivityProvider → transient + IslandStateManager.enqueueNotification
```

## Priority (`IslandActivityKind.priority`)

| Kind | Tier | Persistence |
|------|------|-------------|
| microphone, camera | high | while running |
| audioDevice (route), notification, media | medium | route: persistent metadata; route *change*: transient |
| battery, network | low | (future) |

Presentation hints: `DynamicIslandStateManager.compactActivityIcons`, `transientBanner`; phase control via `IslandStateManager`.

## Public APIs in use

- **Microphone**: `kAudioDevicePropertyDeviceIsRunningSomewhere` on default input — no capture.
- **Camera**: CMIO `kCMIODevicePropertyDeviceIsRunningSomewhere` — no `AVCaptureSession`.
- **Audio**: Core Audio default output + transport type; route changes call `notifyAudioRouteChange`.
- **Media**: `MPNowPlayingInfoCenter` via `MediaActivityProvider` / `NowPlayingMonitor`.
- **Notifications**: `UNUserNotificationCenterDelegate` for **MacOS Hub** notifications only.

## Unsupported (documented)

| Signal | Status |
|--------|--------|
| Other apps' Notification Center | No public API |
| Per-app mic/camera attribution | No public API |
| MRMediaRemote | Not used (private) |
| Third-party players without Now Playing | Often invisible |

## Agent 1 integration

```swift
@ObservedObject private var activities = DynamicIslandStateManager.shared // if exposed as ObservableObject later
// Today: @Observable DynamicIslandStateManager.shared — bind compact icons from sortedActivities / compactActivityIcons
@ObservedObject private var interaction = IslandStateManager.shared

// Diagnostics:
SystemEventManager.shared.providerStatuses()
```
