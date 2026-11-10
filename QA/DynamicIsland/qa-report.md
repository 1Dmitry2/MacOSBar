# Dynamic Island QA report — 2026-11-10

## Environment

| Item | Value |
|------|--------|
| Machine | Built-in Retina, 1470×956 pt |
| Physical top | `NSScreen.frame.maxY` = **956** |
| Menu band | `frame.maxY - visible.maxY` ≈ **33 pt** |
| Safe area top | **32 pt** |
| Notch width (auxiliary areas) | **179 pt** |
| Build | `swift build -c release` → `.build/release/MacOSHub` |
| Tests | `swift test` — **21/21 passed** (including `IslandSerializedTests`) |

## Root cause (geometry)

1. Panel reposition kept a stale top within 80pt of the correct Y, often locking to `visibleFrame.maxY` instead of `frame.maxY`.
2. `NSHostingView` applied container safe area at the top; content sat below the window edge.
3. Hit-test rect used bottom-origin math on a flipped hosting view (`y = height - h` instead of `y = 0`).

**Fix:** anchor to `screen.frame.maxY`; always `panelFrame(topAnchorY:)`; `ignoresSafeArea(.container, edges: .top)`; `safeAreaRegions = []`; top-aligned interactive rect.

## Artifacts

| File | Description |
|------|-------------|
| `settings-audit.md` | Per-control wiring audit |
| `desktop-with-island.png` | Full desktop capture (session) |
| `compact-notch-region.png` | Cropped notch band (manual `screencapture -R`) |

## Automation limitations

- **Computer Use:** blocked — Screen Recording not granted for Cursor Computer Use.
- **Long-run UI session:** SPM `MacOSHub` binary is menubar/headless-friendly; no AppleScript dictionary (`application "MacOSHub"` not found). QA relied on unit tests + `IslandSerializedTests` (live panel start/toggle/stop on main display) + geometry probes.

**Video:** not recorded (no approved screen recorder in automation path).

## Scenario matrix

| Check | Method | Result | Notes |
|-------|--------|--------|-------|
| Совпадение с физическим notch | `NotchLayoutTests.notchedDisplayTopAnchorMatchesPhysicalTop` | **Pass** | `topAnchorY == frame.maxY` |
| Compact State | Unit + `islandPanelStartToggleStop` | **Pass** | Panel at expanded height; SwiftUI compact inside |
| Expanded State | `toggleExpanded` smoke + state tests | **Pass** | Top anchor unchanged (`expandedFrameKeepsTopAnchor`) |
| Hover | `hoverPeek`, `hoverDelayUsesConfiguredTiming` | **Pass** | Hover ≠ user expanded |
| Click | `toggleExpandedFromHoverPinsOpen` | **Pass** | |
| Сворачивание | Smoke toggle ×2 | **Pass** | |
| Отсутствие скачков | `reposition` always uses `fresh.topAnchorY` | **Pass** | No preserve-within-80pt |
| Live Preview | `previewMetricsFollowConfiguration`, settings audit | **Pass** | Same `DynamicIslandView`, `draftSnapshot` |
| Настройки размера | Audit + preview tests | **Pass** | Draft → preview; apply → runtime |
| Настройки внешнего вида | Audit | **Pass** | |
| Настройки виджетов | Audit (was broken) | **Pass** | Real bindings |
| Сохранение конфигурации | `DynamicIslandConfiguration` UserDefaults | **Pass** | Not re-tested across reboot in this session |
| Музыкальная активность | `MediaActivityProvider` | **Not exercised** | Needs Now Playing + manual play |
| Микрофон | Provider unit hints only | **Not exercised** | Needs live mic app |
| Аудиоустройства | Provider present | **Not exercised** | |
| Несколько дисплеев | `HubDisplayResolver` + settings | **Partial** | No external display attached |
| Длительная работа | — | **Not exercised** | Blocked by automation limits |

## Manual follow-up (recommended)

1. Enable Screen Recording for Cursor Computer Use; repeat scenarios 2–4 from the task brief.
2. Play music in Music/Spotify; verify compact icon + expanded metadata.
3. Record **Cmd+Shift+5** clip into `QA/DynamicIsland/` when permissions allow.
