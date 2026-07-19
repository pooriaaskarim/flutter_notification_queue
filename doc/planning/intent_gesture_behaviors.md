# Intent Gesture Behaviors — Implementation Planning

> **Status**: Deferred. Classes exist and are dispatched but the UX,
> state lifecycle, and event integration are incomplete or untested.
> None of these behaviors are exposed in the example app or documented
> in the public README until each item's completion criteria are met.

---

## Affected Classes

| Behavior class | Gesture plugin | Events emitted |
|---|---|---|
| `Pin<T>` | `PinGesturePlugin` | `NotificationPinned`, `NotificationUnpinned` |
| `Snooze<T>` | `SnoozeGesturePlugin` | `NotificationSnoozed` |
| `Archive<T>` | `ArchiveGesturePlugin` | *(none yet — see below)* |
| `CustomAction<T>` | `CustomActionGesturePlugin` | `NotificationCustomActionTriggered` |

All four are defined in
[`lib/src/enums/queue_intents.dart`](../../lib/src/enums/queue_intents.dart),
dispatched via the `switch` in
[`draggable_transitions.dart`](../../lib/src/notification/interaction/widgets/draggable_transitions.dart),
and exported from the public API surface
([`flutter_notification_queue.dart`](../../lib/flutter_notification_queue.dart)).

They are **not** listed in the README, **not** offered in the example
studio's behavior dropdowns, and **not** covered by any integration or
widget tests.

---

## F-P1: `Pin` — Drag-to-Edge Toggle

### What currently exists
- `PinGesturePlugin` handles `onDragStart`/`onDragUpdate`/`onDragEnd`.
- `isPinned` state exists on `NotificationWidget` — auto-dismiss timer
  is already paused when pinned.
- `DismissGesturePlugin.onDragEnd` already checks `isPinned` and plays
  `HapticFeedback.lightImpact` instead of dismissing.
- `NotificationPinned` / `NotificationUnpinned` events are defined and exported.

### What is missing / broken
1. **Visual indicator**: No UI differentiation between a pinned and unpinned
   card. The user has no feedback that the pin took effect. Needs a pin
   badge, border tint, or icon overlay on the card surface.
2. **Drag feedback overlay**: `PinGesturePlugin.buildFeedback` needs an
   overlay that mirrors the `DismissGesturePlugin` drop-zone UI but shows
   a "pin" affordance at the edge instead of a dismiss target.
3. **Unpin affordance**: Currently nothing guides the user to drag again to
   unpin. The toggle logic needs to be clearly reflected in the overlay and
   the card visual state.
4. **Per-notification override**: `NotificationWidget.dragBehavior` can be
   set to `Pin()` per card, but there is no validation that the parent
   queue's `dragBehavior` is compatible.
5. **Tests**: Zero widget or integration tests cover pin/unpin round-trips.

### Completion criteria
- [ ] Pinned card shows a persistent visual badge (pin icon or border).
- [ ] Drag-to-edge produces a "pin / unpin" overlay instead of dismiss zones.
- [ ] `NotificationPinned` / `NotificationUnpinned` are emitted on each
      state toggle and verified in tests.
- [ ] Auto-dismiss timer resumes after unpin (already implemented —
      add a regression test).
- [ ] Example studio exposes `Pin` in the behavior dropdown and has a
      scenario demonstrating toggle.

---

## F-P2: `Snooze` — Drag-to-Dismiss with Timed Resurrection

### What currently exists
- `SnoozeGesturePlugin` exists as a class with the correct signature.
- `Snooze(duration: Duration(...))` constructor is valid and exported.
- `NotificationSnoozed` event is defined.

### What is missing / broken
1. **`onDragEnd` has no resurrection logic**: The plugin likely calls
   `dismiss()` on the card but never schedules the re-show. The
   `NotificationSnoozed` event is probably not emitted. Needs verification
   and, almost certainly, implementation.
2. **Re-show mechanism**: After the snooze duration elapses, the notification
   must be re-queued. This requires either:
   - A coordinator-level `Timer` that calls `notification.show()` after the
     delay, or
   - A pending-queue entry with a wake-time that the coordinator polls.
   Neither exists yet.
3. **State persistence**: If the app is backgrounded or the overlay is
   disposed during the snooze window, the resurrection must not fire into a
   dead tree. The coordinator needs to guard against this.
4. **Overlay feedback**: `buildFeedback` needs a "snooze zone" overlay with a
   clock/time indicator, distinct from dismiss zones.
5. **Tests**: Zero coverage.

### Completion criteria
- [ ] `onDragEnd` emits `NotificationSnoozed` with the correct duration.
- [ ] A `Timer`-based resurrection calls `show()` after the duration and
      re-emits `NotificationQueued`.
- [ ] Resurrection is safely cancelled if the coordinator is disposed.
- [ ] Overlay shows a snooze indicator at the target edge.
- [ ] Widget test: snooze + wait + verify re-appearance with fake async.
- [ ] Example studio exposes `Snooze` with a duration slider and a scenario.

---

## F-P3: `Archive` — Drag-to-Edge Semantic Action

### What currently exists
- `ArchiveGesturePlugin` exists as a class.
- No dedicated event — `NotificationCustomActionTriggered` is **not** what
  archive should emit (archive is a distinct semantic concept).

### What is missing / broken
1. **No dedicated event**: There is no `NotificationArchived` event. Either
   add one or make a deliberate decision to reuse
   `NotificationDismissed(reason: DismissReason.archived)` — but this needs
   to be a conscious, documented choice.
2. **`onDragEnd` implementation**: Needs to call `dismiss()` and emit the
   chosen archive event.
3. **No developer hook**: Unlike `CustomAction`, archive has no `actionName`
   to distinguish it from other drag intents. The developer needs a way to
   observe archive events separately from dismissals.
4. **Overlay feedback**: No archive-specific drop-zone UI (e.g., an archive
   box icon at the screen edge).
5. **Tests**: Zero coverage.

### Completion criteria
- [ ] Define `NotificationArchived` event (or document the
      `DismissReason.archived` decision).
- [ ] `ArchiveGesturePlugin.onDragEnd` dismisses the card and emits the event.
- [ ] Overlay shows an archive affordance at the target edge.
- [ ] Widget test: drag to archive zone → verify event emitted, card dismissed.
- [ ] Example studio exposes `Archive` in the dropdown with a scenario.

---

## F-P4: `CustomAction` — Drag-to-Edge with Developer Callback

### What currently exists
- `CustomActionGesturePlugin` exists with `actionName` plumbing.
- `NotificationCustomActionTriggered(actionName:)` is defined and exported.

### What is missing / broken
1. **Dismiss semantics unclear**: Does a custom action always dismiss the
   card, or should it remain visible? The plugin needs a `dismissOnAction`
   parameter (default `true`) to let the developer decide.
2. **Overlay feedback**: `buildFeedback` needs an overlay that shows the
   `actionName` label at the edge so the user knows what will happen.
3. **Validation**: Empty or whitespace `actionName` should throw at
   construction time (analogous to the `Relocate.to({})` guard).
4. **Tests**: Zero coverage.

### Completion criteria
- [ ] `dismissOnAction` parameter added (default `true`).
- [ ] Overlay shows the `actionName` label at the target edge.
- [ ] Empty `actionName` throws `ArgumentError` at construction.
- [ ] `NotificationCustomActionTriggered` is emitted reliably; widget test
      verifies it appears in `FlutterNotificationQueue.events`.
- [ ] Example studio exposes `CustomAction` with a name text field and a
      scenario that logs the event to the event panel.

---

## Shared Prerequisites

Before any of the above can ship:

1. **Overlay feedback audit**: All four plugins need a distinct, polished
   drop-zone overlay. Currently only `DismissGesturePlugin` and
   `ReorderGesturePlugin` have production-quality overlays.
2. **Integration test harness for intents**: The existing integration test
   framework covers dismiss/relocate/reorder. Extend it to cover intent
   behaviors (drive a drag to the edge, assert the correct event fires).
3. **Example studio event log**: Verify that `NotificationPinned`,
   `NotificationSnoozed`, `NotificationArchived`, and
   `NotificationCustomActionTriggered` are displayed in the event log panel
   before adding scenarios — otherwise the demo is invisible.

---

## Notes on the Existing Export Surface

These types **are currently exported** in the public API even though they are
immature. Before the next public release, consider one of:

- **Option A**: `@experimental` annotate the four classes in their source
  files. This signals caution without breaking the API.
- **Option B**: Hide them from the barrel export until they ship, then
  re-expose in the release that completes them.
- **Option C** (current default): Leave them exported but undocumented.
  Acceptable short-term; high risk of user confusion if discovered.

**Recommendation**: Apply `@experimental` from `package:meta` to `Pin`,
`Snooze`, `Archive`, and `CustomAction` immediately as a minimal,
non-breaking signal.
