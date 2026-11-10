# Changelog

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
