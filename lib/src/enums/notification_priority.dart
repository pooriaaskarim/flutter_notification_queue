part of 'enums.dart';

/// Semantic priority rank of a notification.
///
/// Determines stack priority rendering (auto-sorting) and queue overflow
/// triage (e.g. low-priority items yield to critical alerts).
enum NotificationPriority {
  /// Low priority notification (e.g. casual status messages, background sync
  /// updates).
  low,

  /// Normal priority notification (e.g. regular chats, successful actions).
  normal,

  /// High priority notification (e.g. important alerts, resource usage
  /// warnings).
  high,

  /// Critical priority notification (e.g. system errors, database connection
  /// failures).
  critical;

  bool operator <(final NotificationPriority other) => index < other.index;
  bool operator <=(final NotificationPriority other) => index <= other.index;
  bool operator >(final NotificationPriority other) => index > other.index;
  bool operator >=(final NotificationPriority other) => index >= other.index;
}
