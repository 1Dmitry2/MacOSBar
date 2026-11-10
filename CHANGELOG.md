# Changelog

## [Unreleased]

### Added
- Dynamic Island: top-anchored notch layout via `NSScreen.safeAreaInsets`, `auxiliaryTopLeftArea` / `auxiliaryTopRightArea`, and fixed host window (`panelFrame`) with in-window SwiftUI size animation.
- `SystemEventManager` with `MicrophoneActivityProvider`, `AudioDeviceActivityProvider`, `MediaActivityProvider`, `NotificationActivityProvider` (app-local), and `IslandStateManager` interaction phases (idle/hover/expanded/notification/live).
- Settings: event source toggles reflect real provider support (`IslandEventSourceID` + limitation text).
- Live preview modes: idle, hover, expanded, mic, camera, headphones, music, notification, multiple activities.

### Fixed
- Island no longer anchored below the notch (`bottomAnchorY` → `topAnchorY`); expansion grows downward from the screen top.
- **Notch alignment root cause:** remove stale top preservation in `reposition`, anchor to `NSScreen.frame.maxY`, clear hosting safe area, top-aligned pass-through hit testing.
- **Expanded notch chrome:** `IslandIntegratedShape` keeps the physical lip width on top with continuous black fill and square shoulders when the body widens (no floating rounded cap).
- **Settings:** unified `DynamicIslandConfiguration` (draft/applied, Live Apply, preview uses same `DynamicIslandView`).
- Panel shadow removed; `IslandChrome` capsule in notch-integrated compact mode.
- `HubDynamicIslandTests`: serialized integration suite; top-anchored geometry, hover/click state machine.

### Known API limits (Dynamic Island)
- Camera activity: not implemented (public API gap).
- Microphone: Core Audio running flag only — does not identify the app.
- Media: `MPNowPlayingInfoCenter` — not all players publish metadata.
- Notifications: only this app's `UNUserNotificationCenter` delegate.

## [1.2.0] - 2026-11-10

### Fixed
- Smart Cleaner: missing `cleaner.cat.*` strings (raw keys in UI); layout inside single `ScrollView` (sidebar stability).
- Process names: use `NSRunningApplication` / `proc_pidpath` instead of 16-char `p_comm`.
- Dynamic Island: initial frame at notch, non-movable panel, built-in/main/specific display selection, screen-change handling.

### Added
- `SystemMetricsService` alias; shared `CleanerEngine.shared` with cancelable async scan.
- Menu bar metrics label (CPU/RAM/SSD/temp) and popover panel.
- `MonitorSidebarController` floating monitor panel.
- `HubShortcuts` + Settings UI for global hotkeys.
- Localization tests for cleaner categories and shortcuts.
- Manual QA checklist: [docs/MANUAL_QA.md](docs/MANUAL_QA.md).

## [1.1.0] - 2026-11-10

### Fixed
- Sidebar navigation: explicit row taps, selection highlight, wider column (no dead clicks).
- Module list on Overview (removed duplicate Dynamic Island entry).

### Added
- Russian default localization via `Localizable.xcstrings` + language picker.
- Diagnostics tab with export/clear log.
- Cleaner scan/clean history and confirmation before delete.
- System Monitor: Swift Charts, process CPU sampling, swap usage.
- Temperature probe documentation (public API limitation).
