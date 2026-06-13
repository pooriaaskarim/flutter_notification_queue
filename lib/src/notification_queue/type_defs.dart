part of 'notification_queue.dart';

//todo(pooriaaskarim): needs considerations on when to show, positioning, etc.
typedef QueueIndicatorBuilder = Widget? Function(
  int pendingNotificationsCount,
);

@immutable
class QueueGroupingBehavior {
  const QueueGroupingBehavior({
    this.enabled = false,
    this.maxBeforeGrouping = 2,
  });

  final bool enabled;
  final int maxBeforeGrouping;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is QueueGroupingBehavior &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          maxBeforeGrouping == other.maxBeforeGrouping;

  @override
  int get hashCode => Object.hash(enabled, maxBeforeGrouping);
}
