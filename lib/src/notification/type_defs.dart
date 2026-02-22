part of 'notification.dart';

//TODO: Implement NotificationBuilder
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

/// A utility class for carrying local and global offsets of a drag event.
class OffsetPair {
  const OffsetPair({required this.local, required this.global});
  final Offset local;
  final Offset global;
}
