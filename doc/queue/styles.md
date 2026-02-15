# Queue Styles

A `QueueStyle` defines the visual template for notifications. FNQ comes with several built-in styles.

## Built-in Styles

### 1. FilledQueueStyle (Default)
- **Appearance**: Solid background color (based on channel color).
- **Text**: Contrast color (usually white).
- **Best For**: High-visibility alerts, toasts.

### 2. FlatQueueStyle
- **Appearance**: Transparent background, colored text.
- **Best For**: Subtle notifications, clean interfaces.

### 3. OutlinedQueueStyle
- **Appearance**: Transparent background with a colored border.
- **Best For**: Modern, minimalist designs.

## Customization

You can customize styles when creating valid `NotificationQueue` instances.

```dart
const myStyle = FilledQueueStyle(
  borderRadius: BorderRadius.all(Radius.circular(12)),
  elevation: 4,
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
);
```
