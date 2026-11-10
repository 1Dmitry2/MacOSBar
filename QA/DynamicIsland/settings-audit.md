# Dynamic Island — settings audit

| Control | Section | Binds to | Persists | Live preview | Live island (live apply) | Live island (manual + Apply) | Notes |
|---------|---------|----------|----------|--------------|---------------------------|-------------------------------|-------|
| Enable Dynamic Island | Header | `dynamicIslandEnabled` | Yes | N/A | Yes | Yes | Starts/stops panel |
| Apply changes immediately | Apply mode | `liveApplyEnabled` | Yes | N/A | N/A | N/A | Toggles draft vs manual apply |
| Live Preview mode chips | Preview | `previewMode` (local) | No | Yes | N/A | N/A | Demo presentation modes |
| Play animation | Preview | local | No | Yes | N/A | N/A | Cycles idle → hover → expanded |
| Event source toggles (×6) | Events | `islandEvent*` | Yes | Yes | Yes | On Apply | Provider gates respected |
| Hover expands | Behavior | `islandHoverExpands` | Yes | Yes | Yes | On Apply | |
| Click expands | Behavior | `islandClickExpands` | Yes | Yes | Yes | On Apply | |
| Hover delay slider | Behavior | `islandHoverDelaySeconds` | Yes | Yes | Yes | On Apply | |
| Auto-collapse slider | Behavior | `islandAutoCollapseSeconds` | Yes | Partial | Yes | On Apply | Runtime timer |
| Notification duration | Behavior | `islandNotificationDurationSeconds` | Yes | Partial | Yes | On Apply | |
| Multi-activity toggle | Behavior | `islandMultiActivityEnabled` | Yes | Yes | Yes | On Apply | |
| Max compact icons stepper | Behavior | `islandMaxCompactActivityIcons` | Yes | Yes | Yes | On Apply | Shown when multi on |
| Widget toggles (×9) | Widgets | `islandWidgetShows*` | Yes | Yes | Yes | On Apply | Switches (was broken) |
| Background opacity | Appearance | `islandBackgroundOpacity` | Yes | Yes | Yes | On Apply | |
| Corner radius | Appearance | `islandCornerRadius` | Yes | Yes | Yes | On Apply | |
| Compact width / height | Appearance | `islandCompactWidth/Height` | Yes | Yes | Yes | On Apply | |
| Expanded width / height | Appearance | `islandExpandedWidth/Height` | Yes | Yes | Yes | On Apply | |
| Animation duration | Appearance | `islandAnimationDuration` | Yes | Yes | Yes | On Apply | |
| Display mode picker | Placement | `islandDisplayMode` | Yes | Partial | Yes | On Apply | Reposition panel |
| Specific display picker | Placement | `islandDisplayID` | Yes | Partial | Yes | On Apply | When specific mode |
| Vertical offset slider | Placement | `islandVerticalOffset` | Yes | Partial | Yes | On Apply | Notch offset |
| Reset appearance | Actions | defaults | Yes | Yes | If live / after Apply | Resets appearance fields |
| Revert | Actions | draft ← applied | No | Yes | N/A | Manual only | |
| Apply | Actions | commit draft | Yes | N/A | N/A | Yes | |
| Start / Stop | Actions | controller | N/A | N/A | Yes | Yes | |

**Source of truth:** `DynamicIslandConfiguration.shared` (`HubSettings/DynamicIslandConfiguration.swift`).

**Runtime sync:** `DynamicIslandConfiguration.Notifications.appliedDidChange` → `DynamicIslandController.syncFromConfiguration()`.

**Preview:** `DynamicIslandPreview` + `DynamicIslandView(interactive: false)` read `draftSnapshot`.
