# Queue System

The **Queue System** determines *where* notifications appear on the screen and *how* they stack.

## NotificationQueue

A `NotificationQueue` is a configuration object that defines:
- **Position**: Where on the screen the queue is anchored.
- **Behavior**: How notifications enter, leave, and handle gestures.
- **Transition**: The entrance and exit animation strategy.
- **Close Button**: Visibility strategy (`AlwaysVisible`, `VisibleOnHover`, `Hidden`).
- **Style**: The visual appearance of notifications within this queue.
- **Constraints**: Maximum stack size (`maxStackSize`) and spacing.

### QueuePosition

The `QueuePosition` enum defines available anchor points:
- **Corners**: `topLeft`, `topRight`, `bottomLeft`, `bottomRight`.
- **Centers**: `topCenter`, `bottomCenter`, `centerLeft`, `centerRight`.

## Configuring Queues

You can configure queues during initialization. While `NotificationQueue.defaultQueue` exists for convenience, we recommend using the **Concrete Queue Classes** for clarity and explicit control.

### Transitions

Queues accept a `transition` property of type `NotificationTransition`. Built-in strategies include:
- `SlideTransitionStrategy` (Default)
- `ScaleTransitionStrategy`
- `FadeTransitionStrategy`
- `BuilderTransitionStrategy` (Custom)

### Gestures and Relocation

Behaviors define how users interact with notifications:

- **Relocate**: Allows dragging to other queue positions.
- **Dismiss**: Standard swipe-to-remove.
- **Disabled**: Non-interactive notifications.

> **Relocation Intelligence**: Defining `Relocate.to({...})` automatically generates sibling queues for target positions, inheriting the source's style, transition, and constraints.

### Close Button Visibility

The `closeButtonBehavior` property accepts a `QueueCloseButtonBehavior` instance.

- **AlwaysVisible** (Default): Button is always present.
- **VisibleOnHover**: Adaptive behavior. Hidden on desktop until hover; subtly visible (0.3 opacity) on touch devices to ensure discoverability.
- **Hidden**: Removes the close button.

> [!WARNING]
> **Zombie Prevention**: If you use `Hidden()`, you **must** enable another dismissal method like `Dismiss()` or `Relocate()`. The system validates this at startup to prevent undismissable notifications.

### Using Concrete Classes (Recommended)

Each position has a corresponding class (e.g., `TopRightQueue`, `BottomCenterQueue`).

```dart
FlutterNotificationQueue.initialize(
  queues: {
    // 1. Standard Stack in Top Right
    const TopRightQueue(
      maxStackSize: 5,
      style: FlatQueueStyle(),
    ),
    
    // 2. Snackbar-style in Bottom Center
    const BottomCenterQueue(
      maxStackSize: 1, // Only show one notification at a time
      margin: EdgeInsets.all(24),
    ),

    // 3. Persistent Log in Bottom Left
    const BottomLeftQueue(
      maxStackSize: 10,
      dragBehavior: DragBehavior.disabled(), // Prevent swiping away
    ),
  },
);
```

### Using Default Factory

For quick prototypes, you can use the factory method:

```dart
NotificationQueue.defaultQueue(
  position: QueuePosition.topRight,
  maxStackSize: 3,
);
```
