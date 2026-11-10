# MacOS Hub

Native macOS system utility (Swift 6, SwiftUI + AppKit) combining safe disk cleanup, live system monitoring, optional input lock for cleaning hardware, and a notch-adjacent Dynamic Island panel.

## Requirements

- macOS 14 (Sonoma) or newer
- Xcode 16+ / Swift 6
- Apple Silicon recommended (Intel supported where system APIs allow)

## Build & run

```bash
cd MacOSBar
swift build
swift run MacOSHub
```

For a GUI app bundle, open `Package.swift` in Xcode and run the **MacOSHub** scheme (Product → Run).

## Tests

```bash
swift test
```

## Modules

| Module | Description |
|--------|-------------|
| Smart Cleaner | Allowlisted scan → preview → move to Trash |
| System Monitor | CPU, memory, disk, network, power; process table; monitor sidebar |
| Global Shortcuts | Carbon hotkeys (Settings → Горячие клавиши) |
| Device Control | Event-tap keyboard/pointer filtering + emergency unlock |
| Dynamic Island | Borderless `NSPanel` near the notch; **live settings preview** (`DynamicIslandView`), display targeting & widgets |
| Settings | Modules, intervals, permissions, theme |

See [ARCHITECTURE.md](ARCHITECTURE.md) for design decisions and known limitations.

## Permissions

| Permission | When needed |
|------------|-------------|
| Accessibility | Device Control event tap |
| Input Monitoring | Device Control keyboard monitoring |
| Notifications | Optional alerts |
| Full Disk Access | **Not** required for default cleaner paths |

## Known limitations

- **CPU temperature**: Not available via public APIs on Apple Silicon — UI shows *Unavailable*.
- **Keyboard vs trackpad**: Independent HID disable is not public; filtering uses session event taps (see Device Control notice in app).
- **Cleaner**: Never scans Desktop, Documents, Downloads, Photos, browser profiles, or Application Support by default.

## Project layout

```
Sources/
  HubCore, HubCleaner, HubSystemMonitor, …
  MacOSHub/          — App entry & SwiftUI screens
Tests/
design/              — UI references
```

## License

Personal project — use at your own risk. Always review cleaner preview before deleting files.
