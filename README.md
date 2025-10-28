# FlutterNotificationQueue

[![Pub Version](https://img.shields.io/pub/v/flutter_notification_queue)](https://pub.dev/packages/flutter_notification_queue)
[![Pub Likes](https://img.shields.io/pub/likes/flutter_notification_queue)](https://pub.dev/packages/flutter_notification_queue)
[![Pub Points](https://img.shields.io/pub/points/flutter_notification_queue)](https://pub.dev/packages/flutter_notification_queue)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform: Flutter](https://img.shields.io/badge/Platform-Flutter-blue?logo=flutter)](https://flutter.dev)

A powerful, feature-rich overlay-based notification system for Flutter applications. FlutterNotificationQueue provides a comprehensive solution for displaying in-app notifications with advanced queuing, interactive gestures, multi-language support, and extensive customization options.

## ✨ Key Features

### 🎯 **Advanced Notification System**
- **Multiple Notification Types**: Success, Error, Warning, Info with predefined styling
- **Custom Notifications**: Full control over appearance, behavior, and content
- **Permanent Notifications**: Stay visible until manually dismissed
- **Auto-dismiss with Timer**: Visual progress indicator and configurable duration
- **Expandable Content**: Tap to expand long messages with auto-pause on expansion

### 🚀 **Intelligent Queue Management**
- **Smart Queuing**: FIFO-based queue system with configurable stack limits
- **Multiple Queue Positions**: 8 different screen positions (top, center, bottom + left, center, right)
- **Stack Indicators**: Visual "+N more" badges for queued notifications
- **Channel System**: Organized notification channels with individual configurations
- **Dynamic Relocation**: Drag notifications between different queue positions

### 🎨 **Rich Interactive Features**
- **Drag-to-Dismiss**: Swipe notifications away in any direction
- **Long-press Actions**: Relocate or dismiss with long-press gestures
- **Tap Actions**: Button actions or tap-anywhere functionality
- **Hover Effects**: Close button appears on hover (web/desktop)
- **Gesture Feedback**: Smooth opacity changes during interactions

### 🌍 **Internationalization & Accessibility**
- **RTL Language Support**: Automatic text direction detection for Arabic, Persian, Hebrew, and more
- **Multi-language Examples**: Comprehensive support for 10+ languages
- **Responsive Design**: Adaptive layouts for phone, tablet, and desktop
- **Safe Area Integration**: Automatic handling of notches and status bars
- **Screen Reader Support**: Proper semantic labels and accessibility features

### 🎨 **Extensive Customization**
- **Queue Styles**: Flat, Filled, and Outlined notification styles
- **Color Theming**: Custom colors for each notification type and channel
- **Animation Control**: Configurable entrance/exit animations and curves
- **Layout Customization**: Margins, spacing, elevation, and border radius
- **Custom Builders**: Override notification UI with custom widgets

## 📦 Installation

Add FlutterNotificationQueue to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_notification_queue: ^0.2.0
```

Then run:

```bash
flutter pub get
```

## 🚀 Quick Start

### Basic Usage

```dart
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

// Simple success notification
NotificationWidget(
  message: 'Operation completed successfully!',
  title: 'Success',
  channelName: 'success',
).show(context);

// Error with retry action
NotificationManager.instance.show(
  NotificationWidget(
    channelName: 'error',
    message: 'Network connection failed. Please try again.',
    title: 'Connection Error',
    action: NotificationAction.button(
      label: 'Retry',
      onPressed: () => retryOperation(),
    ),
  ),
  context,
);
```

### Initialize with Custom Configuration

```dart
void main() {
  NotificationManager.initialize(
    channels: {
      const NotificationChannel(
        name: 'success',
        position: QueuePosition.topCenter,
        defaultDismissDuration: Duration(seconds: 3),
        defaultColor: Colors.green,
        defaultIcon: Icon(Icons.check_circle),
      ),
      const NotificationChannel(
        name: 'error',
        position: QueuePosition.topCenter,
        defaultDismissDuration: null, // Permanent
        defaultColor: Colors.red,
        defaultIcon: Icon(Icons.error),
      ),
      // Add more channels...
    },
    queues: {
      TopCenterQueue(
        maxStackSize: 3,
        style: const FilledQueueStyle(),
        dragBehavior: const Dismiss(),
        longPressDragBehavior: Relocate.to({
          QueuePosition.centerLeft,
          QueuePosition.centerRight,
        }),
      ),
      BottomCenterQueue(
        maxStackSize: 1,
        style: const FlatQueueStyle(),
        closeButtonBehavior: QueueCloseButtonBehavior.always,
      ),
    },
  );
  
  runApp(MyApp());
}
```

## 🎨 Advanced Configuration

### Custom Queue Styles

```dart
// Filled style with rounded corners
const FilledQueueStyle(
  borderRadius: BorderRadius.all(Radius.circular(12)),
  opacity: 0.9,
  elevation: 8,
)

// Flat style for minimal design
const FlatQueueStyle(
  borderRadius: BorderRadius.zero,
  opacity: 0.8,
  elevation: 2,
)

// Outlined style with borders
const OutlinedQueueStyle(
  borderRadius: BorderRadius.all(Radius.circular(8)),
  opacity: 0.7,
  elevation: 4,
)
```

### Drag and Gesture Behaviors

```dart
// Dismiss on drag
const Dismiss(thresholdInPixels: 50)

// Relocate to specific positions
Relocate.to({
  QueuePosition.topLeft,
  QueuePosition.topRight,
  QueuePosition.bottomCenter,
})

// Disable gestures
const Disabled()
```

### Close Button Behaviors

```dart
QueueCloseButtonBehavior.always    // Always visible
QueueCloseButtonBehavior.onHover   // Show on hover (web/desktop)
QueueCloseButtonBehavior.never     // Never show
```

## 🌍 Multi-language Support

FlutterNotificationQueue automatically detects text direction and supports RTL languages:

```dart
// Arabic notification
NotificationWidget(
  title: 'إشعار هام',
  message: 'تم تحديث التطبيق بنجاح. يرجى إعادة تشغيل التطبيق.',
  action: NotificationAction.button(
    label: 'إعادة التشغيل',
    onPressed: () => restartApp(),
  ),
).show(context);

// Persian notification
NotificationWidget(
  title: 'اطلاعیه',
  message: 'عملیات با موفقیت انجام شد! سیستم آماده استفاده است.',
  action: NotificationAction.button(
    label: 'تأیید',
    onPressed: () => confirmAction(),
  ),
).show(context);
```

## 📱 Platform-Specific Features

### Mobile (iOS/Android)
- Native gesture recognition
- Haptic feedback support
- Safe area integration
- Optimized touch targets

### Web
- Hover effects and interactions
- Keyboard navigation support
- Close button always available
- Responsive breakpoints

### Desktop (Windows/macOS/Linux)
- Mouse drag support
- Keyboard shortcuts
- Window-aware positioning
- High DPI support

## 🎯 Use Cases

### Success Messages
```dart
NotificationWidget(
  message: 'File saved successfully!',
  title: 'Success',
  channelName: 'success',
  dismissDuration: Duration(seconds: 3),
).show(context);
```

### Error Handling
```dart
NotificationWidget(
  message: 'Failed to connect to server. Please check your internet connection.',
  title: 'Connection Error',
  channelName: 'error',
  action: NotificationAction.button(
    label: 'Retry',
    onPressed: () => retryConnection(),
  ),
).show(context);
```

### Warning Notifications
```dart
NotificationWidget(
  message: 'Low storage space detected. Tap to manage.',
  title: 'Storage Warning',
  channelName: 'warning',
  action: NotificationAction.onTap(
    onPressed: () => openStorageSettings(),
  ),
).show(context);
```

### Info Messages
```dart
NotificationWidget(
  message: 'New features available! Check out our latest update.',
  title: 'App Update',
  channelName: 'info',
  action: NotificationAction.button(
    label: 'Learn More',
    onPressed: () => showUpdateDetails(),
  ),
).show(context);
```

### Permanent Notifications
```dart
NotificationWidget(
  message: 'Important system maintenance scheduled for tonight.',
  title: 'Maintenance Notice',
  dismissDuration: null, // Permanent until dismissed
  action: NotificationAction.button(
    label: 'Dismiss',
    onPressed: () => dismissNotification(),
  ),
).show(context);
```

## 🔧 API Reference

### Core Classes

- **`NotificationWidget`**: Main notification widget with full customization
- **`NotificationManager`**: Singleton for managing notifications and queues
- **`NotificationChannel`**: Configuration for notification types and behavior
- **`NotificationQueue`**: Queue management with position-specific settings
- **`NotificationAction`**: Action system for user interactions

### Queue Positions

- `QueuePosition.topLeft`
- `QueuePosition.topCenter`
- `QueuePosition.topRight`
- `QueuePosition.centerLeft`
- `QueuePosition.centerRight`
- `QueuePosition.bottomLeft`
- `QueuePosition.bottomCenter`
- `QueuePosition.bottomRight`

### Queue Types

- `TopLeftQueue`, `TopCenterQueue`, `TopRightQueue`
- `CenterLeftQueue`, `CenterRightQueue`
- `BottomLeftQueue`, `BottomCenterQueue`, `BottomRightQueue`

### Action Types

```dart
// Button action
NotificationAction.button(
  label: 'Action Label',
  onPressed: () => handleAction(),
)

// Tap action
NotificationAction.onTap(
  onPressed: () => handleTap(),
)
```

## 🎨 Customization Examples

### Custom Notification Builder

```dart
NotificationWidget(
  message: 'Custom styled notification',
  builder: (context, notification) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.purple, Colors.blue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.star, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.message,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
).show(context);
```

### Custom Queue Indicator

```dart
TopCenterQueue(
  queueIndicatorBuilder: (context, count, config) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '+$count',
      style: TextStyle(color: Colors.white, fontSize: 12),
    ),
  ),
)
```

## 📊 Performance Features

- **Efficient Rendering**: Single overlay for all notifications
- **Memory Management**: Automatic cleanup and disposal
- **Lazy Loading**: Notifications built only when needed
- **Gesture Optimization**: Smooth 60fps interactions
- **Queue Efficiency**: O(1) queue operations

## 🧪 Testing

The package includes comprehensive examples and test cases:

```dart
// Test notification display
testWidgets('should display notification', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Trigger notification
  NotificationWidget(message: 'Test').show(context);
  await tester.pump();
  
  // Verify notification appears
  expect(find.text('Test'), findsOneWidget);
});
```

## 📈 Migration Guide

### From 0.1.x to 0.2.0

The API has been significantly enhanced while maintaining backward compatibility:

```dart
// Old way (still works)
context.showSuccess('Message');

// New way (recommended)
NotificationWidget(
  message: 'Message',
  channelName: 'success',
).show(context);
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design team for the design system
- Contributors and users who provide feedback

## 📞 Support

- 📧 **Issues**: [GitHub Issues](https://github.com/pooriaaskarim/flutter_notification_queue/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/pooriaaskarim/flutter_notification_queue/discussions)
- 📖 **Documentation**: [API Reference](https://pub.dev/documentation/flutter_notification_queue/latest/)

---

Made with ❤️ by [Pooria Askari Moqaddam](https://github.com/pooriaaskarim). If you find this package helpful, please consider giving it a ⭐ on GitHub!