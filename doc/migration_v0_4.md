# Migration Guide: Upgrading to v0.4.0 (Architecture Modernization)

This document provides a step-by-step guide to migrate your codebase from **v0.3.x** (global static singleton API) to **v0.4.0** (decoupled Architecture: `NotificationController` + `NotificationScope` + `AppNotification`).

---

## Key Overview of Changes

| v0.3.x Legacy API | v0.4.0 Modern Architecture | Notes |
|---|---|---|
| `FlutterNotificationQueue.configure(...)` | `final controller = NotificationController(...)` | Pure Dart configuration owner |
| `MaterialApp(builder: FlutterNotificationQueue.builder)` | `NotificationScope(controller: controller, child: child!)` | Scoped widget tree overlay binding |
| `NotificationWidget(message: '...').show()` | `controller.show(AppNotification(message: '...'))` | Pure data intent decoupled from rendering widget |
| `NotificationScope.of(context).show(...)` | `NotificationScope.of(context).show(AppNotification(...))` | Context-aware dispatch |
| `FlutterNotificationQueue.events` | `controller.events` | Stream persists across scope mounts |
| `FnqEvent` | `NotificationEvent` | Renamed base class for all events |

---

## Step 1: Upgrading Configuration & Initialization

### Before (v0.3.x)
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

### After (v0.4.0)
```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.controller});

  final NotificationController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => NotificationScope(
        controller: controller,
        child: child!,
      ),
      home: const HomeScreen(),
    );
  }
}
```

---

## Step 2: Dispatching Notifications

### Before (v0.3.x)
```dart
// Creating and showing widget handle directly
NotificationWidget(
  message: 'Order #104 shipped',
  channelName: 'orders',
).show();
```

### After (v0.4.0)

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

### Before (v0.3.x)
```dart
FlutterNotificationQueue.events.listen((FnqEvent event) {
  if (event is NotificationDismissed) {
    print('Notification dismissed: ${event.notification.id}');
  }
});
```

### After (v0.4.0)
```dart
controller.events.listen((NotificationEvent event) {
  if (event is NotificationDismissed) {
    print('Notification dismissed: ${event.notification.id}');
  }
});
```

---

## Release Schedule

- **v0.3.0**: Soft-deprecation warnings introduced alongside additive `NotificationController` and `NotificationScope` APIs.
- **v0.4.0**: Complete removal of legacy static surfaces (`FlutterNotificationQueue` static facade, `NotificationWidget.show()`, `typedef FnqEvent`, and `NotificationAction.onTap`). Standardized entirely on `NotificationController`, `NotificationScope`, and `AppNotification`.
