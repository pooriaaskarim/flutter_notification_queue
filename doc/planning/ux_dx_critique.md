# FNQ UX & DX Critique Report
> **Phase A2–A4 findings** — Based on real-world use-case research, full API surface audit, and static analysis.
> **Baseline**: 177 tests passing, `dart analyze` reports no issues.

---

## Part 1 — Competitor Landscape & Market Positioning (A1)

### What the market uses in 2025–2026

| Package | Market Niche | Key DX Advantage |
|---|---|---|
| `ScaffoldMessenger` | Canonical ephemeral toasts | Zero-config, native Material 3 |
| `toastification` | Multi-queue, modern animations | Visual toast builder tool, 1.2k+ likes |
| `another_flushbar` | Actionable toasts with buttons | FlushKit for server-driven alerts |
| `bot_toast` | Complex overlays, non-Material UI | Rich overlay API, context-free |

### FNQ's unique positioning

FNQ is the **only package** that offers:
1. **Multi-queue spatial layout** (9 screen positions simultaneously)
2. **Drag-to-relocate** (move notifications between queues)
3. **Priority triage** (critical cards preempt lower-priority ones)
4. **Notification grouping / bundling** with live expand/collapse
5. **First-class `FnqEvent` observability stream**

This is an enterprise/power-user differentiator. The README does not communicate this at all — it reads like a basic toast library, which **undersells the product catastrophically**.

---

## Part 2 — UX Critique

### UX-1 ⚠️ Zero-Config Onboarding Gap (CRITICAL)

**Finding**: The README Quick Start uses `FlutterNotificationQueue.initialize()` — **this method does not exist**. The actual API is `FlutterNotificationQueue.configure()`.

```dart
// README says (WRONG):
FlutterNotificationQueue.initialize(channels: {...}, queues: {...});

// Actual API (CORRECT):
FlutterNotificationQueue.configure(channels: {...}, queues: {...});
```

**Impact**: Every first-time user reading the README will encounter an immediate compile error. This is a day-1 blocker. **Fix before any release.**

---

### UX-2 ⚠️ Lazy-Init Is a DX Trap

**Finding**: `FlutterNotificationQueue.configure()` is optional — the system auto-initializes on first access. This is documented but the UX consequence is poor: the first `.show()` call triggers a `Logger.info()` warning _and_ sets up a configuration the developer didn't explicitly choose.

**Problem**: A developer who forgets to call `configure()` will get:
- Notifications on `topCenter` (which may not be their design intent)
- Standard channels pre-configured (may conflict with their channels)
- An info-level logd message they may never see

**Recommendation**: Promote the lazy-init log to `warning` level. Consider asserting in debug mode that `configure()` was called explicitly before the first `show()`. At minimum, document the lazy-init contract clearly in the README.

---

### UX-3 🔸 The Channel vs. Queue Mental Model is Undocumented

**Finding**: `NotificationChannel` and `NotificationQueue` serve distinct but related purposes that are not explained anywhere in the README or API docs.

**Current understanding (from reading source)**:
- **`NotificationQueue`** = spatial container at a screen position. Owns the rendering, gestures, animations, and overflow logic.
- **`NotificationChannel`** = semantic grouping for defaults (color, icon, dismiss duration, priority). Binds to a position via `position` field.

**User mental model gap**: A new user will ask "If my channel has `position: topCenter` and my queue is at `topCenter`, which wins?" The answer (queue's explicit config wins, channel's `position` is a fallback routing hint) is buried in `configuration_manager.dart` and nowhere in the public docs.

**Recommendation**: Add a 2-3 paragraph "Architecture Concepts" section to the README with a simple diagram.

---

### UX-4 🔸 `channelName` is a Magic String with Silent Fallback

**Finding**: When `channelName: 'nonexistent'` is used in `NotificationWidget`, `ConfigurationManager.getChannel()` silently falls back to a default channel and logs at `debug` level. In production (where `logLevel` defaults to `warning`), this failure is **completely invisible**.

```dart
// This silently routes to the default channel in production:
NotificationWidget(
  message: 'Hello',
  channelName: 'typo_in_name', // ← no compile-time check, silent runtime fallback
).show();
```

**Recommendation**: In debug mode, promote the fallback log to `warning`. Optionally provide a `FlutterNotificationQueue.configure(strictChannelLookup: true)` flag that throws instead of falling back.

---

### UX-5 🔸 `dismissDuration` Override Gap (Known TODO in Source)

**Finding**: Line 235–237 of `notification.dart` contains an explicit TODO:

```dart
//todo: what if a channel is set with a specific Duration but
//todo:  user wants a specific descendant notification to be permanent?
//todo: (bool) permanent field for notification or the channel?
```

The current resolution is: `widget.dismissDuration ?? widget.channel.defaultDismissDuration`. This means there is **no way to declare a specific notification as permanent when its channel has a `defaultDismissDuration`** — the `null` signal is ambiguous ("user didn't set it" vs "user wants permanent").

**Impact**: Medium — affects real use cases like "sync in progress" pinned cards in an otherwise auto-dismissing channel.

**Recommendation**: Add `final bool permanent` field to `NotificationWidget`. When `permanent: true`, force `resolvedDismissDuration` to `null` regardless of channel default.

---

### UX-6 🔸 `TapToAct` Queue-Level Default is Confusing

**Finding**: `TapToAct` at the queue level requires a shared `VoidCallback` for all notifications in the queue. This is semantically broken — the callback is defined once on the queue, not per-notification.

```dart
// This is the only way to do queue-level TapToAct today:
NotificationQueue.defaultQueue(
  tapBehavior: TapToAct(
    onTap: () => doSomething(), // ← same callback for ALL notifications
  ),
)
```

Real-world use: every notification needs its own action. The **per-notification `tapBehavior` override** is the actual correct pattern, but the queue-level docs imply it as the primary setup.

**Recommendation**: Add a `TapDisabled` note in the queue-level docs clarifying that `TapToAct` at queue level is edge-case; per-notification override is the primary pattern.

---

### UX-7 🔸 `Relocate.to({...})` Auto-Sibling Magic is Surprising

**Finding**: When a queue has `longPressDragBehavior: Relocate.to({QueuePosition.topRight})`, the system **automatically creates a sibling queue** at `topRight` and **adds the source position to the target set**. This is documented only in the README as a `> [!TIP]` block.

**Problem**: Developer configures one queue, unexpectedly finds two queues active. The sibling queue inherits the source queue's style — but this copy behavior is silent. No event is fired, no log message explains it.

**Recommendation**: Log a `debug` message during `_expandRelocationGroups` naming the positions that were auto-generated. This alone would reduce confusion significantly.

---

### UX-8 🟡 `QueueCoordinator` is Unnecessarily Exported

**Finding**: `QueueCoordinator` is exported in `lib/flutter_notification_queue.dart`. The class has one real use: `FlutterNotificationQueue.coordinator.events` — but `FlutterNotificationQueue.events` is a shorthand that makes the full coordinator export unnecessary for 99% of users.

The `QueueCoordinator` class exposes internal methods like `emitEvent()` (`@visibleForTesting`), `consumeInitializationQueue()`, and `detach()`. Exposing this is a semver risk.

**Recommendation**: Remove `QueueCoordinator` from public exports. Expose only what's needed (the `events` stream is already on `FlutterNotificationQueue`). This is a **breaking change** — must be done before v1.0.

---

### UX-9 🟡 `VisibleOnHover._mouseDetected` is Static Global State

**Finding**: `VisibleOnHover` uses `static bool _mouseDetected = false`. This global persists across tests (causing test pollution) and across app lifecycle events.

```dart
static bool _mouseDetected = false; // ← resets only on app restart
```

**Problems**:
1. In tests: `FlutterNotificationQueue.reset()` does NOT reset this. Tests that fire mouse events will affect all subsequent tests.
2. In app: If a user detaches a physical mouse, the "upgraded" hover state never reverts.

**Recommendation**: Move `_mouseDetected` to instance state in `QueueWidgetState` or tie it to the coordinator lifecycle. Add a `VisibleOnHover.reset()` call inside `FlutterNotificationQueue.reset()`.

---

### UX-10 🟡 `enabled` and `vibrate` on `NotificationChannel` are `//Todo: UnderDevelop`

**Finding**: Lines 196 and 200 of `notification_channel.dart`:
```dart
/// Whether [NotificationWidget]s from this channel should be shown.
//Todo: UnderDevelop
final bool enabled;

/// Whether [NotificationWidget]s from this channel should vibrate.
//Todo: UnderDevelop
final bool vibrate;
```

These are part of the public API. Shipping them as `//Todo: UnderDevelop` to v1.0 is a liability — users will configure them, get no effect, and file bugs.

**Recommendation**: Either implement them before v1.0, mark them `@experimental`, or remove them from the public API (breaking change that's acceptable pre-v1.0).

---

## Part 3 — DX Stability Audit

### DX-1 ⚠️ `FnqEvent` Stream Closes on `reset()` — Listeners Become Zombies (CRITICAL)

**Finding**: `QueueCoordinator.detach()` calls `_eventController.close()`. But `QueueCoordinator` is never replaced — `_coordinator ??= QueueCoordinator()` only creates it once.

After `reset()` is called:
1. `_coordinator` is set to `null`
2. `_coordinator!.detach()` closes the `StreamController`
3. The next `configure()` call creates a **new** `QueueCoordinator` with a **new** `StreamController`
4. But any listener that captured `FlutterNotificationQueue.events` before the reset now holds a reference to the **closed** broadcast stream

```dart
final sub = FlutterNotificationQueue.events.listen(...); // captures stream A
FlutterNotificationQueue.reset();
FlutterNotificationQueue.configure();
// sub still listens to stream A (closed), not the new stream B
```

**Impact**: In production apps that call `configure()` more than once (e.g., when handling user logout/login), listeners attached before the reconfigure become orphans.

**Recommendation**: Provide a stable `Stream<FnqEvent>` façade that re-routes to the current internal controller transparently (e.g., a `StreamController.broadcast()` at the facade level that is never closed).

---

### DX-2 🔸 `DismissReason` Missing `evicted` Case

**Finding**: The `DismissReason` enum has: `timeout`, `userSwipe`, `userTap`, `programmatic`. 

From the KI docs (strategic research), the Priority Triage Engine **evicts** lower-priority notifications when a higher-priority one arrives. But there is no `evicted` dismiss reason.

**Impact**: The event stream cannot distinguish "user dismissed" from "system evicted due to priority". Analytics consumers cannot correctly attribute dismissal causes.

**Recommendation**: Add `DismissReason.evicted` and wire it through the priority triage eviction path in `QueueWidgetState`.

---

### DX-3 🔸 No `dismissDuration: Duration.zero` Guard

**Finding**: Setting `dismissDuration: Duration.zero` is technically valid but semantically broken — the notification will appear and immediately disappear (or potentially cause an animation issue at zero-length duration).

There is no assertion or guard against this in `NotificationWidget`'s factory constructor.

**Recommendation**: Add an assert:
```dart
assert(
  dismissDuration == null || dismissDuration > Duration.zero,
  'dismissDuration must be positive or null (permanent)',
)
```

---

### DX-4 🔸 `maxStackSize: 0` Assertion Exists but `maxPendingSize: 0` Does Not

**Finding**: `NotificationQueue` asserts `maxStackSize > 0` (good). But for `maxPendingSize`, the assertion is `maxPendingSize == null || maxPendingSize > 0` (also good).

However, `maxPendingSize: 0` when `maxStackSize` is also `0` would normally be blocked — but since `maxStackSize: 0` is already caught, this is fine. ✅

The gap: the `QueueOverflowStrategy.discardOldest` evaluates against a `null` `maxPendingSize` (unbounded) — verified in source. This is correct behavior. ✅

---

### DX-5 🔸 `show()` Before `builder` Is in the Tree — Timing Risk

**Finding**: The `queue()` method in `QueueCoordinator` checks if the queue widget is mounted:
```dart
final isMounted = key?.currentState != null;
if (isMounted) {
  key!.currentState!.enqueue(notification);
} else {
  // startup mailbox
  _initializationQueue[...].add(notification);
}
```

Notifications fired before `MaterialApp.builder` runs are queued in `_initializationQueue`. When the `QueueWidget` mounts, it calls `consumeInitializationQueue()` — the startup mailbox empties.

**Gap**: If `show()` is called before `configure()` is called (i.e., before any coordinator exists), the lazy-init fires — which creates a coordinator with default config. Then the widget builds. This flow works _but_ it means the app's actual `configure()` call (in `main()`) must happen before or during `runApp()`, not after.

**Recommendation**: Document this constraint explicitly. Warn in debug mode if `show()` is called before `configure()`.

---

### DX-6 🟡 No Test Helper for Stream Assertions

**Finding**: The `QueueCoordinator` has `@visibleForTesting emitEvent()` — useful for pushing test events. But there is no test utility for asserting events _received_ from the stream.

**Recommendation**: Add to the test utilities (or document a pattern):
```dart
/// Returns a Future that completes with the first FnqEvent of type [T].
Future<T> nextEvent<T extends FnqEvent>() =>
    FlutterNotificationQueue.events.whereType<T>().first;
```

---

### DX-7 🟡 `NotificationWidget.show()` Is Called on a `const`-Adjacent Immutable — Feels Off

**Finding**: The canonical usage is:
```dart
const NotificationWidget(message: 'Hello').show();
```

This pattern has an issue: `NotificationWidget` is `@immutable` but the factory constructor is not `const`. The internal `_.()` constructor is not `const` either (it creates `ValueNotifier` and `DateTime.now()`). So the user cannot write `const NotificationWidget(...)`.

**The UX feel problem**: calling `.show()` on what looks like a data object (a configuration struct) creates a widget and immediately hands it to the system. It mixes construction with side effects in a way that violates the "immutable config" mental model.

**Better pattern** (for consideration):
```dart
// More idiomatic — separates configuration from intent:
NotificationWidget(message: 'Hello').show();

// vs. what competitors do:
toastification.show(context: context, title: 'Hello');
```

**Recommendation**: This is a philosophical choice. For v1.0, document the pattern explicitly. Note: changing it would be a breaking API change. Consider adding a static factory method as an alternative entry point:
```dart
FlutterNotificationQueue.show(message: 'Hello', channelName: 'success');
```

---

## Part 4 — Documentation Audit

| Doc Area | Severity | Finding | Action |
|---|---|---|---|
| README Quick Start | 🔴 CRITICAL | Uses non-existent `initialize()` | Fix to `configure()` |
| README: Architecture | 🔸 IMPORTANT | No Channel vs Queue conceptual explanation | Add "Concepts" section |
| README: `FnqEvent` | 🔸 IMPORTANT | Observability is a major differentiator — not documented | Add full "Observability" section |
| README: Overflow/backpressure | 🔸 IMPORTANT | `maxPendingSize` + `QueueOverflowStrategy` not in README | Add section |
| README: Priority Triage | 🔸 IMPORTANT | `NotificationPriority` not mentioned in README | Add to "Advanced Configuration" |
| README: Notification Grouping | 🔸 IMPORTANT | `groupKey` not in README | Add section |
| README: `enabled` / `vibrate` | 🔸 IMPORTANT | Exported but unimplemented | Remove from docs or mark `@experimental` |
| Migration guide | 🟡 MINOR | Missing 0.4→0.5 section | Write it |
| dartdoc coverage | 🟡 MINOR | `ConfigurationManager` says `@internal` — good. Others need audit | Run `dart doc --validate-links` |
| README: Market positioning | 🟡 MINOR | Reads as a basic toast lib — undersells spatial multi-queue | Rewrite intro section |

---

## Part 5 — Summary: Prioritized Fix List

### 🔴 Must Fix Before v1.0 (Blockers)

| ID | Issue | Effort |
|---|---|---|
| UX-1 | README Quick Start uses wrong API name (`initialize` → `configure`) | S |
| DX-1 | `FnqEvent` stream becomes zombie after `reset()` + `configure()` | M |
| UX-10 | `enabled`/`vibrate` are exported but unimplemented — remove or implement | S |
| UX-8 | `QueueCoordinator` should not be in public exports | S |
| UX-9 | `VisibleOnHover._mouseDetected` global not reset by `FlutterNotificationQueue.reset()` | S |

### 🔸 Important Before v1.0

| ID | Issue | Effort |
|---|---|---|
| DX-2 | Add `DismissReason.evicted` for priority triage dismissals | S |
| UX-5 | No way to force `permanent: true` per-notification in an auto-dismissing channel | S |
| UX-3 | Missing "Concepts" section in README (Channel vs Queue) | M |
| UX-4 | Silent `channelName` fallback — promote to warning in debug | S |
| DX-3 | Add assert for `dismissDuration: Duration.zero` | XS |
| Doc | Add `FnqEvent`, overflow, priority, grouping sections to README | L |

### 🟡 Polish / Nice to Have

| ID | Issue | Effort |
|---|---|---|
| UX-2 | Promote lazy-init log to `warning`, assert in debug | S |
| UX-6 | Clarify `TapToAct` queue-level vs per-notification docs | S |
| UX-7 | Log auto-generated sibling queues during `_expandRelocationGroups` | XS |
| DX-5 | Document `show()` timing constraint relative to `configure()` | S |
| DX-6 | Add test helper for stream event assertions | S |
| UX-7 | Consider `FlutterNotificationQueue.show(...)` static helper | L |

---

> [!NOTE]
> Effort legend: XS = 1–2 hours, S = half-day, M = 1–2 days, L = 3+ days
