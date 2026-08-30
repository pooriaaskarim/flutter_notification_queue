# Channel System (v0.4.x)

The **Channel System** categorizes notifications by intent. It allows you to define global visual themes and default queue targets for different categories of messages.

## `NotificationChannel`

A `NotificationChannel` is a named configuration profile that defines:
- **Name**: Unique string identifier (e.g., `'success'`, `'orders'`, `'chat'`).
- **Colors**: Default background and foreground colors.
- **Icon**: Default icon widget.
- **Target Queue**: Optional `QueuePosition` override to route all channel notifications to a specific queue.
- **Priority**: Default priority tier (`low`, `normal`, `high`, `critical`).
- **Auto-Dismiss Duration**: Default display duration before auto-dismissal.

### Why Use Channels?

1. **Visual Consistency**: Ensures all "Error" or "Success" notifications maintain uniform styling across your app.
2. **Centralized Theming**: Modify the theme or target position of a channel in one place without touching UI dispatch calls.
3. **Intent-First Dispatching**: Call `controller.show(AppNotification(message: '...', channelName: 'orders'))` without manually specifying colors, icons, or positions at every callsite.

---

## Standard Channels

FNQ provides built-in standard channels out of the box:

- **`success`**: Green, Checkmark icon.
- **`error`**: Red, Error icon.
- **`warning`**: Orange, Warning icon.
- **`info`**: Blue, Info icon.

Standard channels are accessible via `NotificationChannel.standardChannels()`.

---

## Custom Channels & Controller Setup

Define your own channels and pass them to your `NotificationController`:

```dart
final chatChannel = const NotificationChannel(
  name: 'chat',
  defaultIcon: Icon(Icons.chat_bubble),
  defaultColor: Colors.purple,
  position: QueuePosition.topRight,
);

final controller = NotificationController(
  channels: {
    ...NotificationChannel.standardChannels(),
    chatChannel,
  },
);
```
