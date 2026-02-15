# Notification Overlay

The **Notification Overlay** is the invisible layer that sits above your app content and hosts the notification queues.

## Mechanism

FNQ uses Flutter's `Overlay` mechanism to float widgets on top of the application content. It specifically leverages `OverlayPortal` for optimized performance and flexibility in rendering.

## Integration

### FlutterNotificationQueue.builder

The recommended integration method is via the `builder` parameter of `MaterialApp` or `CupertinoApp`.

```dart
MaterialApp(
  // ...
  builder: FlutterNotificationQueue.builder,
)
```

This method automatically:
1.  Wraps the app in a `NotificationOverlay`.
2.  Ensures the overlay is above the Navigator, allowing notifications to appear over dialogs and routes.

### Manual Integration

If the `builder` method is not suitable, the `NotificationOverlay` widget can be manually inserted into the widget tree. It must be placed high enough in the hierarchy to cover all relevant screens.

```dart
Directionality(
  textDirection: TextDirection.ltr,
  child: NotificationOverlay(
    child: MyAppContent(),
  ),
)
```
