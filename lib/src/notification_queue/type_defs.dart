part of 'notification_queue.dart';

//todo(pooriaaskarim): needs considerations on when to show, positioning, etc.
typedef QueueIndicatorBuilder = Widget? Function(
  int pendingNotificationsCount,
);
