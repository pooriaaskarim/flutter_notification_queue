part of 'notification.dart';

typedef NotificationBuilder = NotificationWidget Function({
  String? title,
  String message,
  NotificationAction? action,
  Widget? icon,
  Color? backgroundColor,
  Color? foregroundColor,
  Duration? dismissDuration,
  QueuePosition? position,
});
