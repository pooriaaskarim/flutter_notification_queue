part of 'notification_queue.dart';

//todo(pooriaaskarim): needs considerations on when to show, positioning, etc.
typedef PendingIndicatorBuilder = Widget? Function(
  int pendingNotificationsCount,
);
