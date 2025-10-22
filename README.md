# flutter_notification_queue

[![Pub Version](https://img.shields.io/pub/v/flutter_notification_queue)](https://pub.dev/packages/flutter_notification_queue)
[![Pub Likes](https://img.shields.io/pub/likes/flutter_notification_queue)](https://pub.dev/packages/flutter_notification_queue)
[![Pub Points](https://img.shields.io/pub/points/flutter_notification_queue)](https://pub.dev/packages/flutter_notification_queue)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform: Flutter](https://img.shields.io/badge/Platform-Flutter-blue?logo=flutter)](https://flutter.dev)

A lightweight, customizable overlay-based in-app notification system for Flutter. Display toasts, banners, or alerts with queuing, stacking, drag-to-dismiss, expandable content, and global configuration. Perfect for success messages, errors, warnings, or info alerts—zero dependencies, pure Flutter.

## Features

🎉 **Core Notification System**
- Ready-to-use types: Success ✅, Error ❌, Warning ⚠️, Info ℹ️
- Customizable message, title, icon, colors, and actions
- Automatic dismiss with visual timer progress bar
- Permanent notifications
- Expandable for long content

🚀 **Interactive Gestures**
- Drag/swipe-to-dismiss in any direction with opacity feedback
- Tap actions: Whole notification tap or dedicated button
- Close button (configurable, always on web if enabled)

📚 **Queue & Stack Management**
- Intelligent queuing with FIFO order
- Configurable max stack size (default: 2)
- Stack indicator for queued items ("+ N more" badge, customizable)
- Efficient single-overlay rendering for performance

🎨 **Customization & Theming**
- Global config via `flutter_notification_queueConfig` (colors, duration, position, etc.)
- Position options: Top/Bottom + Start/Center/End
- Runtime config updates (rebuild active notifications)
- Custom builders for notifications and stack indicator
- Theme integration: Fallback to Material colors

🌍 **Accessibility & Compatibility**
- RTL support with auto text direction detection
- Responsive design for phone, tablet, desktop
- SafeArea integration to avoid notches/status bars
- Cross-platform: iOS, Android, Web, Desktop (zero deps)

🔧 **Developer-Friendly**
- Context extensions: `context.showSuccess('Done!')`
- Lightweight: No external dependencies
- Debug logging for easy troubleshooting
- Comprehensive error handling (e.g., require action for permanent)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_notification_queue: ^0.2.0
```

Then run:

```bash
flutter pub get
```

Import in your Dart code:

```dart
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
```

## Quick Start

Show a simple success notification:

```dart
context.showSuccess('Operation completed!');
```

With title and action:

```dart
context.showError(
  'Something went wrong',
  title: 'Error',
  action: flutter_notification_queueAction.button(
    label: 'Retry',
    onPressed: () => retryOperation(),
  ),
);
```

Permanent notification (stays until dismissed):

```dart
context.showInfo(
  'Important update available',
  permanent: true,
  action: flutter_notification_queueAction.onTap(
    onPressed: () => openUpdatePage(),
  ),
);
```

## Configuration

Customize globally via the manager:

```dart
flutter_notification_queueManager.instance.config = flutter_notification_queueConfig(
  successColor: Colors.green[700],
  defaultDismissDuration: const Duration(seconds: 5),
  position: flutter_notification_queuePosition.topCenter,
  maxStackSize: 3,
  stackIndicatorBuilder: (context, length, config) => CustomBadge(length),
);
```

All changes propagate to active notifications. For subtree-specific configs, wrap with `flutter_notification_queueProvider` (optional advanced feature):

```dart
flutter_notification_queueProvider(
  config: flutter_notification_queueConfig(position: flutter_notification_queuePosition.bottomEnd),
  child: MyWidget(),
);
```

### Config Options Table

| Option                   | Type                                                           | Default Value        | Description                           |
|--------------------------|----------------------------------------------------------------|----------------------|---------------------------------------|
| `infoColor`              | `Color`                                                        | `#51B4FA`            | Info background color                 |
| `warningColor`           | `Color`                                                        | `#C97726`            | Warning background color              |
| `errorColor`             | `Color`                                                        | `#D03333`            | Error background color                |
| `successColor`           | `Color`                                                        | `#2D7513`            | Success background color              |
| `foregroundColor`        | `Color?`                                                       | `Colors.white`       | Text/icon color (falls back to theme) |
| `backgroundColor`        | `Color?`                                                       | null (theme primary) | Global background fallback            |
| `defaultDismissDuration` | `Duration`                                                     | `3 seconds`          | Auto-dismiss time                     |
| `position`               | `flutter_notification_queuePosition`                                    | `bottomCenter`       | Stack placement                       |
| `opacity`                | `double`                                                       | `0.8`                | Background transparency               |
| `elevation`              | `double`                                                       | `6.0`                | Card shadow depth                     |
| `maxStackSize`           | `int`                                                          | `2`                  | Max visible at once                   |
| `dismissalThreshold`     | `double`                                                       | `10.0`               | Drag dismiss pixels                   |
| `defaultShowCloseButton` | `bool`                                                         | `false`              | Always show close                     |
| `stackIndicatorBuilder`  | `Widget Function(BuildContext, int, flutter_notification_queueConfig)?` | null (default badge) | Custom "+ N more" UI                  |

## Advanced Usage

### Custom Notification Layout
Override the entire notification UI via config:

```dart
flutter_notification_queueManager.instance.config = flutter_notification_queueConfig(
  notificationBuilder: (context, notification) => CustomNotificationWidget(notification),
);
```

### Positions
Choose from enums like `flutter_notification_queuePosition.topStart` for flexible placement.

### Permanent Mode
Use `permanent: true` to disable auto-dismiss (shows pinned icon, requires action/close for dismissal).

### Handling Queues
The manager automatically queues excess notifications, showing a customizable indicator until space frees up.

## Platform-Specific Notes

- **Android**: Drag gestures with haptics (add via config if desired). Tested on min SDK 21+.
- **iOS**: SafeArea handles notches; gestures feel native.
- **Web**: Close button always available (configurable); keyboard Escape for dismiss (implement via config flag if needed).
- **Desktop**: Responsive widths via utils; mouse drag supported.

For full compatibility, test on your target platforms. No extra setup required.

## Example App

Check the `example/` folder for a complete demo app showcasing all features, including config changes, multiple types, permanent notifications, and position variations.

![Success Notification Demo](https://via.placeholder.com/400x200?text=Success+Demo+GIF) <!-- Replace with actual GIF -->

![Drag Dismiss](https://via.placeholder.com/400x200?text=Drag+Dismiss+GIF) <!-- Replace with actual GIF -->

## API Reference

- `flutter_notification_queueManager.instance.show(notification, context)`: Enqueue and display.
- `flutter_notification_queueAction.button(label, onPressed)`: Add action button.
- `flutter_notification_queueAction.onTap(onPressed)`: Tap whole notification.
- Full config via `flutter_notification_queueConfig` (see table above).

For more, see the source docs or example code.

## Contributing

Contributions welcome! Fork the repo, create a branch, add tests, and PR. Follow [Contributor Covenant](https://www.contributor-covenant.org).

- Report issues: [GitHub Issues](https://github.com/pooriaaskarim/flutter_notification_queue/issues)
- Feature requests: Label as "enhancement"

By contributing, you agree to the MIT License terms.

## License

This package is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

Made with ❤️ by [Pooria Askari Moqaddam](https://github.com/pooriaaskarim). Star the repo if useful!

