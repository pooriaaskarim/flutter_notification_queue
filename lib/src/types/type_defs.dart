import 'package:flutter/widgets.dart';

import '../enums/enums.dart';
import '../notification/notification.dart';

/// Builder function for custom notification widgets.
typedef NotificationBuilder = Widget Function({
  String? title,
  String message,
  NotificationAction? action,
  Widget? icon,
  Color? backgroundColor,
  Color? foregroundColor,
  Duration? dismissDuration,
  QueuePosition? position,
});

/// Builder function for custom queue overflow indicators.
typedef QueueIndicatorBuilder = Widget? Function(
  int pendingNotificationsCount,
);
