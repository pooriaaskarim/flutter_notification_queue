part of 'queue_manager.dart';

//todo(pooriaaskarim): needs considerations on when to show, positioning, etc.
typedef QueueIndicatorBuilder = Widget Function(
  BuildContext context,
  int pendingNotificationsCount,
  int activeNotificationsCount,
);
