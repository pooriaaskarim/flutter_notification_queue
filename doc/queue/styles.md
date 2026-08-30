# Queue Styles (v0.4.x)

A `QueueStyle` defines the visual visual template and stacking presentation for notifications within a `NotificationQueue`.

## Built-in Styles

### 1. `StackedQueueStyle` (Default)
- **Appearance**: Cards stack on top of each other with slight vertical offsets and perspective scaling.
- **Best For**: Modern card stacks, grouped notification decks, interactive reordering.

### 2. `FlatQueueStyle`
- **Appearance**: Solid channel background color with high-contrast content text.
- **Best For**: High-visibility alerts, toasts, snackbars.

### 3. `OutlinedQueueStyle`
- **Appearance**: Semi-transparent or frosted background with a distinct colored border.
- **Best For**: Minimalist interfaces, dark mode UI, subtle system logs.

## Customization & Properties

Styles can be customized when defining a `NotificationQueue`:

```dart
const customStyle = StackedQueueStyle(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  elevation: 6.0,
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
);

const myQueue = NotificationQueue(
  position: QueuePosition.topRight,
  style: customStyle,
);
```
