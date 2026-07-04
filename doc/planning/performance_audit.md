# FNQ Performance Audit Report

> **Track B — Phases B1–B3**
> Source-code based analysis against identified risk areas.
> Device benchmark runs are Phase B4 (pending hardware execution).

---

## Platform Support Matrix (B1)

| Platform | Flutter Support | FNQ-specific Notes |
|---|---|---|
| Android | ✅ Primary | Haptics: `HapticFeedback.lightImpact/mediumImpact/heavyImpact` |
| iOS | ✅ Primary | Same as Android, safe area integration |
| Web (Chrome/Edge) | ✅ Secondary | Hover works; haptics no-op (graceful) |
| Web (Firefox/Safari) | ✅ Secondary | CanvasKit may differ — needs explicit test |
| macOS | ✅ Secondary | Mouse drag, no haptics |
| Linux | ✅ Secondary | Mouse drag, no haptics |
| Windows | ✅ Secondary | Mouse drag, no haptics |

**Confirmed** from source: No `dart:html`, `dart:io`, or platform-specific imports exist in `lib/`. The package is structurally cross-platform.

---

## Frame Budget Targets (B2)

| Scenario | Target | Measurement Method |
|---|---|---|
| Idle (notification visible, no interaction) | 60fps, ≤1 drop/sec | DevTools Timeline |
| Notification entry animation | 60fps | DevTools Timeline |
| Drag-to-dismiss gesture | 60fps (120 on ProMotion) | DevTools Timeline |
| Reorder drag with shift animations | 60fps | DevTools Timeline |
| Notification burst (10 in 1sec) | 60fps during burst | DevTools Timeline + memory snapshot |
| 100-notification cycle (show + auto-dismiss) | Memory flat after GC | Observatory heap snapshot |

---

## Risk Area Findings (B3)

### Risk 1 — No `RepaintBoundary` Around Notification Cards (**HIGH**)

**Finding**: `grep -r "RepaintBoundary" lib/` returns **zero results**.

Every notification card is rendered directly inside the `QueueWidget`'s `Column` (built inside `CustomMultiChildLayout`). When any part of the queue's state changes (e.g., `updateDragTarget`, `setActiveDragGroup`, or a new notification entering), the entire queue subtree — all visible cards — is rasterized again.

**Impact during drag**: `updateDragTarget()` calls `setState()` on every hover frame during reordering (up to 120Hz on ProMotion devices). Without `RepaintBoundary`, each `setState` triggers a full re-rasterization of the `Column` and all its card children, even cards that haven't visually changed.

**Recommended fix**:
```dart
// In _buildItem (QueueWidget.build), wrap each card:
return RepaintBoundary(
  child: _NotificationCard(item: item, queue: widget.queue),
);
```

**Effort**: S — add `RepaintBoundary` around each card in the item builder.

---

### Risk 2 — `updateDragTarget` Triggers `setState` at 120Hz (**HIGH**)

**Finding**: During reordering, the `DraggableTransitionsState` calls `queueState.updateDragTarget(index)` on every drag update event. Inside `QueueWidgetState`:

```dart
void updateDragTarget(final int targetIndex) {
  if (_draggedTargetIndex != targetIndex) {
    setState(() {                          // ← full rebuild of QueueWidgetState
      _draggedTargetIndex = targetIndex;
    });
  }
}
```

This `setState` rebuilds the entire `Column` with all cards on every slot transition. While the `if (_draggedTargetIndex != targetIndex)` guard reduces frequency, at 120Hz polling with active hand movement it still triggers multiple full rebuilds per second.

**Recommended fix**: Replace `_draggedTargetIndex` with a `ValueNotifier<int?>` and wrap only the translation calculation in a `ValueListenableBuilder`:

```dart
// In QueueWidgetState:
final dragTargetIndexNotifier = ValueNotifier<int?>(null);

// In the item builder for each card:
ValueListenableBuilder<int?>(
  valueListenable: dragTargetIndexNotifier,
  builder: (context, dragTargetIndex, child) {
    final translateY = getTranslationY(i, dragTargetIndex);
    return Transform.translate(offset: Offset(0, translateY), child: child);
  },
  child: StaticCardContent(...), // cached, skips rebuild
)
```

**Effort**: M — requires restructuring the reorder drift calculation.

---

### Risk 3 — `_processPending` Calls `setState` per Notification in a Burst (**MEDIUM**)

**Finding**: When a burst of notifications arrives (e.g., 5 items enqueued simultaneously), `_processPending` is called once per notification via the `enqueue()` path, and each call to add an item to `_items` triggers a separate `setState`:

```dart
void _processPending() {
  while (_pendingNotifications.isNotEmpty && _items.length < limit) {
    // ...
    setState(() {          // ← one setState per notification added
      _items.add(item);
    });
    controller.forward();
  }
}
```

A burst of 3 notifications (up to `maxStackSize`) produces 3 sequential `setState` calls, each scheduling a frame. In practice Flutter coalesces many of these, but it's not guaranteed under heavy load.

**Recommended fix**: Batch all item additions into a single `setState`:

```dart
void _processPending() {
  final toAdd = <_NotificationItemState>[];
  while (_pendingNotifications.isNotEmpty && _items.length + toAdd.length < limit) {
    final notification = _pendingNotifications.removeFirst();
    final controller = AnimationController(vsync: this, ...);
    toAdd.add(_NotificationItemState(widget: notification, controller: controller));
  }
  if (toAdd.isNotEmpty) {
    setState(() => _items.addAll(toAdd));
    for (final item in toAdd) {
      item.controller.forward();
    }
  }
}
```

**Effort**: XS — simple batching refactor.

---

### Risk 4 — AnimationController Disposal Coverage (**LOW — VERIFIED CORRECT**)

**Finding**: Three `controller.dispose()` call sites found:
1. `QueueWidgetState.dispose()` (line 147) — disposes all items on widget unmount ✅
2. `_removeItem` (line 552) — disposes the controller after exit animation completes ✅
3. `_removeItemImmediate` (line 626) — disposes immediately for programmatic removal ✅

The eviction path (`_triagePriorityEviction`) calls `_animateExit()` which eventually routes to `_removeItem` — disposal is covered. ✅

**Priority Triage Eviction dismiss reason gap** (from DX-2): The eviction calls `_animateExit` with no reason parameter, defaulting to `DismissReason.programmatic`. This is technically incorrect and should use a dedicated `DismissReason.evicted`.

**Effort**: XS — one-line fix once `DismissReason.evicted` is added.

---

### Risk 5 — `FnqEvent` Stream Never Closed in Facade (**MEDIUM — Lifecycle Risk**)

**Finding**: `QueueCoordinator._eventController` is a `StreamController.broadcast()`. It is closed in `detach()`. However:

1. `FlutterNotificationQueue.reset()` calls `detach()` which closes the controller.
2. The next `configure()` creates a new `QueueCoordinator` with a new `StreamController`.
3. Old listeners on the closed stream receive no more events and no error.
4. Apps that call `FlutterNotificationQueue.events.listen(...)` once (e.g. in `initState`) and hold the subscription through a `configure()` call are silently orphaned.

**Recommended fix**: Introduce a stable stream proxy at the facade level:

```dart
// In FlutterNotificationQueue:
static final _proxyController = StreamController<FnqEvent>.broadcast();
static Stream<FnqEvent> get events => _proxyController.stream;

// When configure() creates/replaces the coordinator:
_coordinator.events.listen(_proxyController.add);
```

This decouples the public API stream lifetime from the coordinator's internal lifecycle.

**Effort**: S — introduce proxy controller.

---

### Risk 6 — `_NotificationQueueStack` Rebuilds on Active-Queue Map Changes (**LOW — Acceptable**)

**Finding**: `_NotificationQueueStack.build()` uses a `ValueListenableBuilder` on `coordinator.activeQueues`. Every time a new notification queue becomes active or inactive (first notification shown / last one dismissed), the entire `CustomMultiChildLayout` rebuilds with a new `children` list.

**Assessment**: This is correct and necessary — the layout must add/remove `QueueWidget` children as queues activate/deactivate. The rebuild is O(active_queues), which in real-world use is 1–3 queues. **This is not a performance problem in practice.**

**One optimization possible**: Queue widgets are keyed by `coordinator.getWidgetKey(queue.position)`, so Flutter correctly reuses existing widget states. The `CustomMultiChildLayout` itself does a full relayout, but individual `QueueWidget` states are preserved. ✅

---

### Risk 7 — `VisibleOnHover._mouseDetected` Static State (**LOW — Test Isolation**)

**Finding**: `VisibleOnHover._mouseDetected` is a `static bool`. It is never reset by `FlutterNotificationQueue.reset()`. 

**Performance impact**: None — it's a simple boolean read.
**Test isolation impact**: High — any test that fires a hover event (via `WidgetTester.sendEventToBinding` or `TestGesture`) permanently flips this to `true` for all subsequent tests in the same test process. This can cause false test failures.

**Recommended fix**: Add `VisibleOnHover._mouseDetected = false;` to `FlutterNotificationQueue.reset()`.

**Effort**: XS.

---

## Summary: Performance Risk Matrix

| Risk | Severity | Found | Effort | Action |
|---|---|---|---|---|
| No `RepaintBoundary` on cards | 🔴 HIGH | Confirmed absent | S | Add in `_buildItem` |
| `updateDragTarget` setState at 120Hz | 🔴 HIGH | Confirmed | M | Replace with `ValueNotifier` |
| `_processPending` multi-setState burst | 🟡 MEDIUM | Confirmed | XS | Batch `setState` |
| `FnqEvent` stream lifecycle zombie | 🟡 MEDIUM | Confirmed | S | Introduce proxy stream |
| AnimationController disposal | ✅ LOW | Verified correct | XS | Add `evicted` reason only |
| `_NotificationQueueStack` rebuild | ✅ LOW | Acceptable | — | No action needed |
| `VisibleOnHover` static reset | 🟡 MEDIUM | Confirmed | XS | Reset in `FlutterNotificationQueue.reset()` |

---

## Phase B4 — Platform Test Checklist

To be executed once fixes from B3 are applied:

### Android / iOS
- [ ] Frame rate during `Dismiss` drag: ≥60fps on Pixel 4a class device
- [ ] Frame rate during `Reorder` drag: ≥60fps (without Risk-1/2 fixes: expect drops)
- [ ] Memory after 100-notification burst cycle: flat after GC
- [ ] Haptic feedback fires at correct FSM stages (lift, slot-enter, confirm)
- [ ] Safe area respected on notched devices (Pixel 6+, iPhone 14+)

### Web (Chrome — CanvasKit)
- [ ] `VisibleOnHover` close button: fade at 400ms easeOutCubic ✓
- [ ] `Dismiss` drag behaves identically to mobile (pointer events)
- [ ] No `dart:io` import errors on web compile
- [ ] `flutter run -d chrome --web-renderer canvaskit` completes

### Desktop (Linux reference)
- [ ] `LongPressDraggable` triggers at appropriate threshold for mouse
- [ ] Window resize does not break queue positioning
- [ ] `Escape` key dismisses newest notification ✓ (seen in source at overlay level)
- [ ] `Shift+Escape` dismisses all notifications ✓ (seen in source)
