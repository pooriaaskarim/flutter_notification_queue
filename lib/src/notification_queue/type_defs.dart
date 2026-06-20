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
    this.maxStackedLayers = 2,
    this.stackStepOffset = 6.0,
    this.stackScaleMultiplier = 0.05,
    this.enableGroupSwipeDismiss = false,
    this.groupDismissThreshold = 0.4,
  });

  final bool enabled;
  final int maxBeforeGrouping;
  final int maxStackedLayers;
  final double stackStepOffset;
  final double stackScaleMultiplier;
  final bool enableGroupSwipeDismiss;
  final double groupDismissThreshold;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is QueueGroupingBehavior &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          maxBeforeGrouping == other.maxBeforeGrouping &&
          maxStackedLayers == other.maxStackedLayers &&
          stackStepOffset == other.stackStepOffset &&
          stackScaleMultiplier == other.stackScaleMultiplier &&
          enableGroupSwipeDismiss == other.enableGroupSwipeDismiss &&
          groupDismissThreshold == other.groupDismissThreshold;

  @override
  int get hashCode => Object.hash(
        enabled,
        maxBeforeGrouping,
        maxStackedLayers,
        stackStepOffset,
        stackScaleMultiplier,
        enableGroupSwipeDismiss,
        groupDismissThreshold,
      );
}
