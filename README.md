# FlutterNotificationQueue
<!--[![Pub Version](https://img.shields.io/pub/v/flutter_notification_queue)](https://pub.dev/packages/flutter_notification_queue)
[![Pub Likes](https://img.shields.io/pub/likes/flutter_notification_queue)](https://pub.dev/packages/flutter_notification_queue)
[![Pub Points](https://img.shields.io/pub/points/flutter_notification_queue)](https://pub.dev/packages/flutter_notification_queue)-->
[![License: BSD 3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Platform: Flutter](https://img.shields.io/badge/Platform-Flutter-blue?logo=flutter)](https://flutter.dev)
<p align="center">
<img width="380" height="380" alt="Q Icon" src="https://github.com/user-attachments/assets/e1751f71-3dfd-417f-a01f-27336d1ecb7d" />
</p>

A Dart overlay-based notification service for Flutter applications. **Flutter Notification Queue** provides a comprehensive solution for displaying in-app notifications with advanced queuing, interactive gestures, multi-language support, and extensive customization options.
Currently available for Android and Web. 

## ✨ Key Features

### 🎯 **Advanced Notification System**
- Intelligent Queueing with **NotificationQueue**s: Define screen positions, notification styles, and behaviors in one place. 
- Categorizing with **NotificationChannel**s: Define styling and theme (e.g., Success, Error, Warning, Info, Scaffold, etc.), Heptic Feedback, and Enabled/Disabled categories all in one place.
- Various **Dismission** behaviors of Queues Notifications 
- Advanced dynamic **Relocation** of Queues Notifications
- **Customizabke Animations**
- **Permanent Notifications**: Stay visible until manually dismissed
- **Auto-dismiss with Timer**: Visual progress indicator and configurable duration
  
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

```bash
flutter pub add flutter_notification_queue
```

Or
```yaml
dependencies:
  flutter_notification_queue: ^latest_version
```
Then run:
```bash
flutter pub get
```

## 🚀 Quick Start

## Basic Usage
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
```dart
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

// Widget show(context) Method
NotificationWidget(
    message: 'Operation completed successfully!',
    title: 'Success',
    channelName: 'success').show(context);

// Manager show(notification, context) Method
NotificationManager.instance.show(
    NotificationWidget(
    message: 'Operation completed successfully!',
    title: 'Success',
    channelName: 'success'),
  context);
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
const Dismiss(
    thresholdInPixels: 50,
  )

// Relocate to specific positions
Relocate.to({
    QueuePosition.topLeft,
    QueuePosition.topRight,
    QueuePosition.bottomCenter,
  })

// Disable gestures
const
Disabled()
```

### Close Button Behaviors

```dart
QueueCloseButtonBehavior.always // Always visible
QueueCloseButtonBehavior.onHover // Show on hover (web/desktop)
QueueCloseButtonBehavior.never // Never show
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
    onPressed: () => restartApp(),),
  ).show(context);

// Persian notification
NotificationWidget(
    title: 'اطلاعیه',
    message: 'عملیات با موفقیت انجام شد! سیستم آماده استفاده است.',
    action: NotificationAction.button(
    label: 'تأیید',
    onPressed: () => confirmAction()),
  ).show(context);
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you'd like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](https://github.com/pooriaaskarim/flutter_notification_queue/blob/master/LICENSE) file for
details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design team for the design system
- Contributors and users who provide feedback

## 📞 Support

- 📧 **Issues**: [GitHub Issues](https://github.com/pooriaaskarim/flutter_notification_queue/issues)
- 💬 **Discussions
  **: [GitHub Discussions](https://github.com/pooriaaskarim/flutter_notification_queue/discussions)
- 📖 **Documentation
  **: [API Reference](https://pub.dev/documentation/flutter_notification_queue/latest/)

---

Made with ❤️ by [Pooria Askari Moqaddam](https://github.com/pooriaaskarim). If you find this package
helpful, please consider giving it a ⭐ on GitHub!
