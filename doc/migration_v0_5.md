# Migration Guide: Upgrading to v0.5.0

This document outlines the architectural changes, removals, and deprecation paths introduced in **v0.5.0** as part of FNQ's transition toward a pure, standard-library architecture for **v1.0**.

---

## 🏛️ The Four Architectural Tiers

In v0.5.0, FNQ formalizes a strict separation of concerns across four orthogonal tiers:

```
┌────────────────────────────────────────────────────────────────────────┐
│                      FNQ ARCHITECTURAL TIERS                           │
├───────────────────┬────────────────────────────┬───────────────────────┤
│ Tier              │ Public API Construct       │ Architectural Role    │
├───────────────────┼────────────────────────────┼───────────────────────┤
│ 1. Surface Owner  │ NotificationScope /        │ Global state, overlay │
│                   │ NotificationController     │ portals, dispatch API │
│                   │                            │                       │
│ 2. Spatial Anchor │ NotificationQueue          │ Screen position,      │
│                   │ └── style: QueueStyle      │ physics, container    │
│                   │     (Filled/Outlined/Flat) │ anatomy & geometry    │
│                   │                            │                       │
│ 3. Domain Routing │ NotificationChannel        │ Domain triage, target │
│                   │ └── theme:                 │ queue position,       │
│                   │     NotificationThemeData  │ chromatics/typography │
│                   │                            │                       │
│ 4. Event Payload  │ AppNotification            │ Business event data,  │
│                   │ └── accentColor            │ title, message, tint  │
└───────────────────┴────────────────────────────┴───────────────────────┘
```

---

## 📋 Summary of Changes

| Change | Type | Impact & Action Required |
|---|---|---|
| **Permanent Queue Relocation** | 🟢 New Feature | Configure `permanentRelocation: QueuePosition?` on `QueueBehavior` or `NotificationQueue`. Queues redirect incoming & pending notifications. Channels have zero relocation logic. |
| **`QueueStyle` Strict Ownership** | 🟢 Standardized | `QueueStyle` lives **strictly on `NotificationQueue`**. It governs physical card geometry (`borderRadius`, `padding`, `opacity`, `elevation`). Channels do not take styles. |
| **`NotificationThemeData` Token System** | 🟢 New Feature | Introduced unified `NotificationThemeData` driven parametrically by `color` and Material 3 design tokens. |
| **Loose Scalar Colors** | 🟡 Deprecated | Deprecated `color`, `defaultColor`, `defaultBackgroundColor`, and `defaultForegroundColor`. Use `NotificationThemeData`. |
| **Removal of `Archive<T>`** | 🔴 Breaking | `Archive<T>` and `ArchiveGesturePlugin` are completely removed. Use `Dismiss` or listen to `NotificationDismissed` / `HistoryLogger`. |
| **`targetPosition` on `show()`** | 🟢 New Feature | Supply `targetPosition` to `controller.show()` for contextual dispatch placement overrides. |
| **`AppNotification.position`** | 🟡 Deprecated | Deprecated on data payloads. Use `NotificationChannel.position` or `controller.show(..., targetPosition:)`. |
| **Per-Notification Gestures** | 🟡 Deprecated | `dragBehavior` and `longPressDragBehavior` on `AppNotification` are deprecated. Viewport gestures belong on `NotificationQueue`. |
| **`initialIsPinned` & `snoozedAt`** | 🟡 Deprecated | Deprecated on `AppNotification`. Use `permanent: true` or `controller.pin(id)`. |
| **Standardized Box Model** | 🟢 Standardized | Standardized `margin` (safe-area), `spacing` (between cards), and `padding` (card internal insets). |
| **Experimental Drag Intents** | 🔵 Annotated | `Pin<T>`, `Snooze<T>`, and `CustomAction<T>` are annotated `@experimental`. |

---

## 1. Permanent Queue Relocation

### Rationale
In previous iterations, routing and redirecting notifications between spatial positions was ambiguous or tied to individual channels. In **v0.5.0**, permanent relocation is strictly a **Queue Behavior**. 

When a queue is permanently relocated, any notification dispatched to that queue—as well as any waiting notifications already queued in its backlog—are automatically migrated to the destination queue. **Channels do not configure relocation**, keeping domain triage clean and predictable.

### Migration

```dart
// ✅ RECOMMENDED (v0.5.0+)
final controller = NotificationController(
  queues: {
    // Top-Center is permanently relocated to Top-Right:
    NotificationQueue(
      position: QueuePosition.topCenter,
      behavior: const QueueBehavior(
        permanentRelocation: QueuePosition.topRight,
      ),
    ),
    const NotificationQueue(
      position: QueuePosition.topRight,
      style: FilledQueueStyle(),
    ),
  },
);
```

You can also specify `permanentRelocation` directly on `NotificationQueue`:
```dart
const NotificationQueue(
  position: QueuePosition.topCenter,
  permanentRelocation: QueuePosition.topRight,
);
```

---

## 2. Strict Single Ownership: `QueueStyle` vs. `NotificationThemeData`

### Rationale
To eliminate styling ambiguity, FNQ enforces strict single ownership:
- **`QueueStyle` lives strictly on `NotificationQueue`**: It acts as the physical industrial chassis (`borderRadius`, `borderWidth`, `elevation`, `opacity`, `padding`). It answers *how the card is built physically*.
- **`NotificationThemeData` lives on `NotificationChannel`, `AppNotification`, and `ThemeData.extensions`**: It acts as the semantic domain voice (`color`, typography, icon themes). It answers *what tone the notification speaks in*.

`NotificationChannel` and `AppNotification` **do not have a `style` parameter**.

### Migration

```dart
// ❌ WRONG (v0.5.0 will not compile)
NotificationChannel(
  name: 'billing',
  style: const FilledQueueStyle(), // Error: style does not exist on NotificationChannel
);

// ✅ CORRECT (v0.5.0+)
// Configure geometry & archetype on the Queue:
NotificationQueue(
  position: QueuePosition.topRight,
  style: const FilledQueueStyle(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    elevation: 4.0,
  ),
);

// Configure semantic colors & typography on the Channel:
NotificationChannel(
  name: 'billing',
  theme: NotificationThemeData.fromSeed(
    seedColor: const Color(0xFF6366F1),
  ),
);
```

---

## 3. Lean Parametric Color Driver (`NotificationThemeData`)

### Rationale
Loose scalar colors (`defaultColor`, `defaultBackgroundColor`, `defaultForegroundColor`) lacked dark/light mode responsiveness and introduced WCAG contrast hazards. In v0.5.0, these fields are deprecated in favor of `NotificationThemeData(color: ...)`.

`color` acts as the single primary visual driver. The active `QueueStyle` archetype deterministically governs how `color` is distributed:
- **`FilledQueueStyle`**: The card body fills with `color`. Foreground text and icons automatically calculate contrast (`luminance > 0.5 ? Colors.black : Colors.white`).
- **`OutlinedQueueStyle`**: The background remains the ambient `colorScheme.surface`; the border stroke and icons are tinted by `color`.
- **`FlatQueueStyle`**: The background remains the ambient `colorScheme.surface`; the leading edge accent strip and icons are tinted by `color`.
- **Drop Shadows**: Optical shadows are governed by ambient `Theme.of(context).shadowColor` and the queue's `elevation`, not by domain channels.

### Migration

```dart
// ⚠️ DEPRECATED (v0.5.x) — will be removed in v0.6.0
NotificationChannel(
  name: 'orders',
  defaultColor: Colors.blue,
  defaultBackgroundColor: Colors.black,
);

// ✅ RECOMMENDED (v0.5.0+)
// Option A: Use Material 3 ColorScheme derive
NotificationChannel(
  name: 'orders',
  theme: NotificationThemeData.fromColorScheme(
    Theme.of(context).colorScheme,
    priority: NotificationPriority.normal,
  ),
);

// Option B: Use built-in presets
NotificationChannel(
  name: 'success',
  theme: NotificationThemeData.success(),
);

// Option C: Global registration via ThemeExtensions in main.dart
MaterialApp(
  theme: ThemeData(
    extensions: const [
      NotificationThemeData(color: Color(0xFF6366F1)),
    ],
  ),
);
```

---

## 4. Standardized Box Model Spacing

### Rationale
Spacing properties across queues and styles have been aligned with the standard Flutter Box Model:
1. **`margin`** (`NotificationQueue`): Inset between the screen safe-area boundaries and the queue container.
2. **`spacing`** (`NotificationQueue`): Gap between adjacent stacked notification cards.
3. **`padding`** (`QueueStyle`): Inset from card perimeter to inner title/message content.

```dart
NotificationQueue(
  position: QueuePosition.topRight,
  margin: const EdgeInsets.all(16),  // Safe-area boundary spacing
  spacing: 8.0,                      // Inter-card gap
  style: const FilledQueueStyle(
    padding: EdgeInsets.all(12),     // Intra-card content padding
  ),
);
```

---

## 5. Removal of `Archive` Behavior

### Rationale
FNQ is an ephemeral toast/banner overlay, not a persistent inbox. Previously, `Archive` drag behavior was an illusion that removed the notification from the queue and emitted an `'archive'` string, identical to dismissal.

### Migration
Replace `Archive<T>` with `Dismiss<T>`:

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

To retain an audit trail of dismissed notifications, query the in-app history logger:
```dart
final history = controller.getHistory(channelName: 'orders');
```

---

## 6. Dispatch-Time Positioning (`targetPosition`)

### Rationale
Hardcoding screen coordinates inside domain objects couples business logic to UI geometry. Positioning belongs canonically to `NotificationChannel.position`. When a one-off contextual placement is necessary, it is specified by the UI caller at dispatch time.

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

## 7. Deprecation of Per-Notification Gesture Overrides

### Rationale
Allowing individual notifications to override queue-level drag physics destroys user muscle memory and predictability. Viewport drag gestures belong strictly to `NotificationQueue`.

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

## 8. Persistent & Pinned State Unification

### Rationale
`initialIsPinned` and `permanent` were redundant. In v0.5.0, `permanent: true` is the canonical blueprint property for notifications that should stay on screen indefinitely until user or programmatic action.

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
