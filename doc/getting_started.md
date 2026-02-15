# Getting Started with FNQ

## 1. Installation

Add `flutter_notification_queue` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_notification_queue: ^Latest
```

## 2. Initialization

Initialize the system in your `main()` function. You can use the zero-config setup for standard defaults.

```dart
void main() {
  // Initialize with standard defaults
  FlutterNotificationQueue.initialize();
  
  runApp(const MyApp());
}
```

## 3. Integration

Integrate the overlay into your app using the `builder` property of `MaterialApp` (or `CupertinoApp`). This ensures notifications can be shown without needing a `BuildContext` at the call site.

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FNQ Demo',
      // Attach the notification overlay
      builder: FlutterNotificationQueue.builder,
      home: const MyHomePage(),
    );
  }
}
```

## 4. Showing a Notification

Instantiate a `NotificationWidget` and call `show()` to display it.

```dart
NotificationWidget(
  title: 'Hello World',
  message: 'This is my first notification!',
  channelName: 'success', // or 'error', 'info', 'warning'
).show();
```

## 5. Configuration

You can customize queues and channels during initialization. Instead of the default factory, you can use concrete queue classes for specific positions.

```dart
FlutterNotificationQueue.initialize(
  queues: {
    const TopRightQueue(
      maxStackSize: 5,
      style: const FlatQueueStyle(),
    ),
  },
  channels: {
     NotificationChannel(
       name: 'custom_alert',
       defaultColor: Colors.purple,
       defaultIcon: Icon(Icons.star),
     ),
  },
);
```
