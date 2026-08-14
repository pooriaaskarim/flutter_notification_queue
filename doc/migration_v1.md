# Migration Guide: Upgrading to v1.0 (Architecture Modernization)

This document provides a step-by-step guide to migrate your codebase from **v0.x** (global static singleton API) to **v1.0** (decoupled Architecture: `NotificationController` + `NotificationScope` + `AppNotification`).

---

## Key Overview of Changes

| v0.x Legacy API | v1.0 Modern Architecture | Notes |
|---|---|---|
| `FlutterNotificationQueue.configure(...)` | `final controller = NotificationController(...)` | Pure Dart configuration owner |
| `MaterialApp(builder: FlutterNotificationQueue.builder)` | `NotificationScope(controller: controller, child: child!)` | Scoped widget tree overlay binding |
| `NotificationWidget(message: '...').show()` | `controller.show(AppNotification(message: '...'))` | Pure data intent decoupled from rendering widget |
| `NotificationScope.of(context).show(...)` | `NotificationScope.of(context).show(AppNotification(...))` | Context-aware dispatch |
| `FlutterNotificationQueue.events` | `controller.events` | Stream persists across scope mounts |
| `FnqEvent` | `NotificationEvent` | Renamed base class for all events |

---

## Step 1: Upgrading Configuration & Initialization

### Before (v0.x)
```dart
void main() {
  FlutterNotificationQueue.configure(
    queues: {const NotificationQueue(position: QueuePosition.topRight)},
    channels: {const NotificationChannel(name: 'orders')},
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: FlutterNotificationQueue.builder,
      home: const HomeScreen(),
    );
  }
}
```

### After (v1.0)


class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.controller});

  final notificationController = NotificationController(
    queues: {const NotificationQueue(position: QueuePosition.topRight)},
    channels: {const NotificationChannel(name: 'orders')},
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => NotificationScope(
        controller: notificationController,
        child: child!,
      ),
      home: const HomeScreen(),
    );
  }
}
```

---

## Step 2: Dispatching Notifications

### Before (v0.x)
```dart
// Creating and showing widget handle directly
NotificationWidget(
  message: 'Order #104 shipped',
  channelName: 'orders',
).show();
```

### After (v1.0)

#### Option A: Contextless (from BLoCs, Services, or Repositories)
```dart
controller.show(
  const AppNotification(
    message: 'Order #104 shipped',
    channelName: 'orders',
  ),
);
```

#### Option B: Context-aware (from UI Widgets)
```dart
NotificationScope.of(context).show(
  const AppNotification(
    message: 'Order #104 shipped',
    channelName: 'orders',
  ),
);
```

---

## Step 3: Listening to Lifecycle Events

### Before (v0.x)
```dart
FlutterNotificationQueue.events.listen((FnqEvent event) {
  if (event is NotificationDismissed) {
    print('Notification dismissed: ${event.notification.id}');
  }
});
```

### After (v1.0)
```dart
controller.events.listen((NotificationEvent event) {
  if (event is NotificationDismissed) {
    print('Notification dismissed: ${event.notification.id}');
  }
});
```

---

## Deprecation Schedule

- **v0.3.0**: `FlutterNotificationQueue`, `NotificationWidget.show()`, and `FnqEvent` are marked `@Deprecated` with compiler warnings and migration guidance. Existing v0.x code continues to work without breaking.
- **v1.0.0**: Deprecated APIs will be removed completely.
