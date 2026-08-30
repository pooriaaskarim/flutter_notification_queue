# Queue System (v0.4.x)

The **Queue System** determines *where* notifications appear on the screen, *how* they stack, how overflow/capacity rules behave, and how gesture intents operate.

## `NotificationQueue`

A `NotificationQueue` is an immutable configuration value object that defines:
- **Position**: Spatial anchor on the screen (`QueuePosition`).
- **Drag Behavior**: Interaction intent (`Dismiss`, `Reorder`, `Relocate`, `ReorderAndRelocate`, `Disabled`).
- **Transition**: Entrance and exit animation strategy (`Slide`, `Scale`, `Fade`, `Custom`).
- **Close Button**: Visibility strategy (`AlwaysVisible`, `VisibleOnHover`, `Hidden`).
- **Style**: Visual layout template (`StackedQueueStyle`, `FlatQueueStyle`, `OutlinedQueueStyle`).
- **Grouping**: Deck aggregation rules (`QueueGroupingBehavior`).
- **Constraints**: Maximum stack size (`maxStackSize`), capacity strategy (`overflowStrategy`), and margins.

---

### `QueuePosition`

The `QueuePosition` enum defines 8 spatial anchor points on screen:
- **Corners**: `topLeft`, `topRight`, `bottomLeft`, `bottomRight`.
- **Centers**: `topCenter`, `bottomCenter`, `centerLeft`, `centerRight`.

---

## Gesture & Interaction Behaviors

Queue behavior governs how users interact with notification cards in the stack:

- **`Dismiss()`**: Standard directional swipe to dismiss.
- **`Reorder()`**: Drag up/down to reorder notifications within the stack.
- **`Relocate()`**: Drag notification cards across queue positions.
- **`ReorderAndRelocate()`**: Hybrid spatial drag supporting both in-queue reordering and cross-queue relocation.
- **`Disabled()`**: Non-interactive notification cards.

> **Relocation Intelligence**: Defining relocation destinations automatically provisions sibling target queues with inherited styles and transitions.

---

## Notification Grouping / Bundling (`QueueGroupingBehavior`)

When multiple notifications target the same channel or group key, `QueueGroupingBehavior` aggregates them into visual card decks:

```dart
const NotificationQueue(
  position: QueuePosition.topRight,
  groupingBehavior: QueueGroupingBehavior(
    enabled: true,
    maxBeforeGrouping: 2,
    maxStackedLayers: 3,
    enableGroupSwipeDismiss: true,
  ),
)
```

- **Representative Card**: Top card surfaces the newest message while showing a group badge (e.g. `+3`).
- **Drag-to-Reveal / Peek**: Swiping down/aside reveals underlying cards without breaking the group.
- **Group Swipe Dismiss**: Swipe to dismiss the representative card or the entire stack deck.

---

## Close Button Visibility (`QueueCloseButtonBehavior`)

The `closeButtonBehavior` property accepts a `QueueCloseButtonBehavior` strategy:

- **`AlwaysVisible()`** (Default): Close button is always rendered at 1.0 opacity.
- **`VisibleOnHover()`**: Adaptive behavior. Fully visible on hover; semi-transparent (0.3 opacity) on touch viewports for discoverability.
- **`Hidden()`**: Removes the visual close button.

> [!WARNING]
> **Safety Assertion**: If `Hidden()` close button is selected, the queue must have an interactive drag behavior enabled (e.g. `Dismiss()`) or auto-dismiss duration configured to prevent undismissable cards.

---

## Configuring Queues in `NotificationController`

Configure queues by passing a `Set<NotificationQueue>` to your `NotificationController`:

```dart
final controller = NotificationController(
  queues: {
    // 1. Stacked Deck in Top Right
    const NotificationQueue(
      position: QueuePosition.topRight,
      maxStackSize: 5,
      style: StackedQueueStyle(),
      dragBehavior: ReorderAndRelocate(),
    ),
    
    // 2. Snackbar Toast in Bottom Center
    const NotificationQueue(
      position: QueuePosition.bottomCenter,
      maxStackSize: 1,
      margin: EdgeInsets.all(24),
      dragBehavior: Dismiss(),
    ),

    // 3. Persistent Alert Log in Bottom Left
    const NotificationQueue(
      position: QueuePosition.bottomLeft,
      maxStackSize: 10,
      dragBehavior: Disabled(),
    ),
  },
);
```
