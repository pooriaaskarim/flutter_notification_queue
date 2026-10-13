# Migration Guide: Upgrading to v0.5.0

This document outlines the architectural changes, removals, and deprecation paths introduced in **v0.5.0** as part of FNQ's transition toward a pure, standard-library architecture for **v1.0**.

---

## 📋 Summary of Changes

| Change | Type | Impact & Action Required |
|---|---|---|
| **Removal of `Archive<T>`** | 🔴 Breaking | `Archive<T>` and `ArchiveGesturePlugin` are completely removed. Use `Dismiss` or listen to `NotificationDismissed` / `HistoryLogger`. |
| **`targetPosition` on `show()`** | 🟢 New Feature | Supply `targetPosition` to `controller.show()` for contextual placement overrides. |
| **`AppNotification.position`** | 🟡 Deprecated | Deprecated on data payloads. Use `NotificationChannel.position` or `controller.show(..., targetPosition:)`. |
| **Per-Notification Gestures** | 🟡 Deprecated | `dragBehavior` and `longPressDragBehavior` on `AppNotification` are deprecated. Viewport gestures belong on `NotificationQueue`. |
| **`initialIsPinned` & `snoozedAt`** | 🟡 Deprecated | Deprecated on `AppNotification`. Use `permanent: true` or `controller.pin(id)`. |
| **`NotificationThemeData` & Styling** | 🟢 New / 🟡 Deprecated | Introduced `NotificationThemeData` and `style` on Channel/Notification; deprecated loose scalar colors (`color`, `defaultColor`, etc.). |
| **Experimental Drag Intents** | 🔵 Annotated | `Pin<T>`, `Snooze<T>`, and `CustomAction<T>` are annotated `@experimental`. |

---

## 1. Removal of `Archive` Behavior

### Rationale
FNQ is an ephemeral heads-up toast/banner overlay, not a persistent message inbox. Previously, `Archive` drag behavior was an illusion that simply removed the notification from the queue and emitted an `'archive'` string, identical to dismissal.

### Migration
If you were using `Archive<T>` in your queue behaviors:

```dart
// ❌ BEFORE (v0.4.x)
NotificationQueue(
  position: QueuePosition.topRight,
  dragBehavior: const Archive(),
);

// ✅ AFTER (v0.5.0)
NotificationQueue(
  position: QueuePosition.topRight,
  dragBehavior: const Dismiss(),
);
```

To retain a persistent audit trail of dismissed notifications, query the in-app history logger:
```dart
final history = controller.getHistory(channelName: 'orders');
```

---

## 2. Dispatch-Time Positioning (`targetPosition`)

### Rationale
An `AppNotification` represents a pure domain intent (data payload). Hardcoding screen coordinates inside domain objects couples business logic to UI geometry. Positioning belongs canonically to `NotificationChannel.position`. When a one-off contextual placement is necessary, it is specified by the UI caller at dispatch time.

### Migration

```dart
// ⚠️ DEPRECATED (v0.5.x) — will be removed in v0.6.0
final notif = AppNotification(
  message: 'Copied to clipboard',
  position: QueuePosition.bottomCenter, // Deprecated!
);
controller.show(notif);

// ✅ RECOMMENDED (v0.5.0+)
final notif = AppNotification(
  message: 'Copied to clipboard',
  channelName: 'system',
);
// Option A: Follow channel default (recommended)
controller.show(notif);

// Option B: Contextual dispatch override from UI
controller.show(
  notif,
  targetPosition: QueuePosition.bottomCenter,
);
```

---

## 3. Deprecation of Per-Notification Gesture Overrides

### Rationale
Allowing individual notifications to override queue-level drag physics (e.g. hijacking swipe-to-dismiss into drag-to-pin) destroys user muscle memory and predictability. Viewport drag gestures belong strictly to `NotificationQueue`.

### Migration

```dart
// ⚠️ DEPRECATED (v0.5.x)
final notif = AppNotification(
  message: 'Action required',
  dragBehavior: const Pin(), // Deprecated!
);

// ✅ RECOMMENDED (v0.5.0+)
// Keep queue gestures consistent, and use action buttons for notification interactions:
final notif = AppNotification(
  message: 'Action required',
  action: NotificationAction.button(
    label: 'Pin',
    onPressed: () => controller.pin(notif.id!),
  ),
);
```

---

## 4. Persistent & Pinned State Unification

### Rationale
`initialIsPinned` and `permanent` were confusingly redundant. In v0.5.0, `permanent: true` is the canonical blueprint property for notifications that should stay on screen indefinitely until user or programmatic action.

### Migration

```dart
// ⚠️ DEPRECATED (v0.5.x)
final notif = AppNotification(
  message: 'Syncing files...',
  initialIsPinned: true, // Deprecated!
);

// ✅ RECOMMENDED (v0.5.0+)
final notif = AppNotification(
  message: 'Syncing files...',
  permanent: true,
);

// Or manage runtime pinning via controller:
controller.pin(notif.id!);
controller.unpin(notif.id!);
```

---

## 5. Theme Token Architecture (`NotificationThemeData`)

### Rationale
Loose, unvalidated scalar color properties (`color`, `backgroundColor`, `foregroundColor` on `AppNotification`, and `defaultColor`, etc. on `NotificationChannel`) fail to react dynamically to dark/light mode switches, introduce WCAG contrast hazards, and lack token representation for typography, shapes, and borders.

In **v0.5.0**, loose color fields are marked `@Deprecated` (scheduled for removal in `v0.6.0`). The unified, dark-mode reactive **`NotificationThemeData`** and archetype **`QueueStyle`** overrides are now standard.

### Migration

```dart
// ⚠️ DEPRECATED (v0.5.x)
NotificationChannel(
  name: 'billing',
  defaultColor: Color(0xFF6366F1),
  defaultBackgroundColor: Colors.black,
);

// ✅ RECOMMENDED (v0.5.0+)
NotificationChannel(
  name: 'billing',
  theme: NotificationThemeData.fromSeed(
    seedColor: const Color(0xFF6366F1),
    brightness: Brightness.dark,
  ),
  style: const FilledQueueStyle(), // Optional archetype override
);

// Per-notification theme tokens:
controller.show(
  AppNotification(
    message: 'Spotify: Playing Track',
    theme: const NotificationThemeData(
      accentColor: Color(0xFF1DB954),
      backgroundColor: Color(0xFF121212),
      foregroundColor: Colors.white,
    ),
  ),
);
```

See [Theme Token Architecture Specification](planning/theme_token_architecture_spec.md) for full details.
