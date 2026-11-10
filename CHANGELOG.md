# Changelog

## [Unreleased]

### Added
- Dynamic Island: shared `DynamicIslandView` + `DynamicIslandPreview` on Settings → Dynamic Island (compact/expanded/notification/activity/music/monitor modes).
- Widget toggles (incl. temperature with availability note), expanded/compact width, animation speed, auto-collapse, hover expand.
- `HubDynamicIslandTests` for layout metrics and bottom-anchored expansion.

### Fixed
- Island expand animation: persistent SwiftUI host (no `rootView` swap on tap); reduce motion via `IslandAnimationPolicy`.
- Horizontal centering uses `visibleFrame.midX`.

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
- Device Control card UI with confirmations.

## [1.0.0] - 2026-11-10

### Added
- Modular Swift Package architecture (HubCore, Cleaner, Monitor, Device Control, Dynamic Island).
- Main window with sidebar navigation and dark-first UI aligned to design references.
- Smart Cleaner with allowlisted paths, safety validation, scan preview, Trash-based cleanup.
- System Monitor with real CPU/memory/disk/network/power metrics and menu bar extra.
- Device Control with event-tap locking, auto-unlock timer, Command+Command emergency unlock.
- Dynamic Island floating panel (time, CPU, RAM, battery) with expand animation.
- Settings, permissions manager, unit tests.

### Known gaps
- CPU temperature monitoring not implemented (no public API).
- Per-process CPU % in process table requires extended sampling (shows memory ranking first).
