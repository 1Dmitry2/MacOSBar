# MacOS Hub — Architecture

## Platform
- macOS 14+ (Sonoma), Swift 6, SwiftUI + AppKit
- Apple Silicon first; Intel via universal where possible

## Module map (Swift PM targets)

| Target | Responsibility |
|--------|----------------|
| `HubCore` | Lifecycle, module registry, theme, shared models |
| `HubDiagnostics` | Structured logging (`os.Logger`) |
| `HubPermissions` | TCC status + deep links to System Settings |
| `HubSettings` | Typed `UserDefaults` / app configuration |
| `HubSystemMonitor` | CPU, memory, disk, network, processes |
| `HubCleaner` | Allowlisted scan, classify, validate, clean |
| `HubDeviceControl` | CGEvent tap input filtering + emergency unlock |
| `HubDynamicIsland` | Top-anchored `NSPanel`, `NotchLayout`, `SystemEventManager`, `IslandStateManager`, widgets |
| `MacOSHub` | App entry, navigation, Menu Bar, window policy |

No circular dependencies: feature modules depend on Core/Diagnostics/Settings only.

## Known API limits (documented in UI)

- **CPU temperature**: No supported public API on Apple Silicon without SIP-breaking tools → show *Unavailable*.
- **Per-device keyboard vs trackpad lock**: Public API filters events globally via event tap (Accessibility + Input Monitoring). Built-in keyboard and trackpad are not independently switchable at HID layer without private IOHID APIs. UI explains this; taps block keyboard-only or pointer-only event types respectively.
- **Music / third-party apps**: No unofficial injection; Now Playing uses `MPNowPlayingInfoCenter` / MediaPlayer when available.
- **Dynamic Island mic**: Default input `kAudioDevicePropertyDeviceIsRunningSomewhere` (heuristic; no app attribution).
- **Dynamic Island camera**: No supported third-party system-wide camera activity API.
- **Dynamic Island notifications**: App-local `UNUserNotificationCenter` only — not other apps' Notification Center items.
- **Island system events**: `HubDynamicIsland/SystemEvents/` — Core Audio mic/device hints, CMIO camera running state, local notifications only. See `SYSTEM_EVENTS.md` for limits (no system-wide Notification Center, no MRMediaRemote).

## Cleaner safety model

1. Fixed allowlist roots (`~/Library/Caches`, system temp, etc.) — never user `Documents`, `Desktop`, `Downloads`, Photos, Application Support content by default.
2. Per-category analyzers with explicit rules.
3. `SafetyValidator` rejects symlinks escaping allowlist, protected suffixes, browser profile paths.
4. Preview → user confirmation → delete (optional move to Trash via `FileManager`).

## Background behavior

- `NSApplicationDelegate`: do not terminate when last window closes.
- Menu Bar extra for monitor + quick module access.
- Dynamic Island panel owned by `HubDynamicIsland` service, started when module enabled.

## Testing

- Unit: path validation, classification, safety, monitor math.
- Cleaner fixture tree under `Tests/Fixtures/CleanerSafety/`.
