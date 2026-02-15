# Channel System

The **Channel System** categorizes notifications by intent. It allows you to define global defaults for different types of messages.

## NotificationChannel

A `NotificationChannel` is a named configuration profile that defines:
- **Name**: Unique identifier (e.g., 'success', 'chat_message').
- **Colors**: Default background and foreground colors.
- **Icon**: Default icon.
- **Target Queue**: Which queue position this channel should use by default.

### Why Use Channels?

1.  **Consistency**: Ensure all "Error" messages look the same across your app.
2.  **Maintainability**: Change the color of all "Success" messages in one place.
3.  **Simplicity**: Call `NotificationWidget.show(channel: 'error')` instead of manually styling every widget.

## Standard Channels

FNQ comes with 4 standard channels out of the box:

- **success**: Green, Checkmark icon.
- **error**: Red, Error icon.
- **warning**: Orange, Warning icon.
- **info**: Blue, Info icon.

These are available via `NotificationChannel.standardChannels()`.

## Custom Channels

Define your own channels for app-specific needs:

```dart
final chatChannel = NotificationChannel(
  name: 'chat',
  defaultIcon: Icon(Icons.chat_bubble),
  defaultColor: Colors.purple,
);

FlutterNotificationQueue.initialize(
  channels: {
    ...NotificationChannel.standardChannels(),
    chatChannel,
  },
);
```
