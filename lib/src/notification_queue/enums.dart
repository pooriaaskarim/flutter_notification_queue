part of 'notification_queue.dart';

enum QueuePosition {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight;

  NotificationQueue generateQueueFrom(final NotificationQueue anotherQueue) =>
      generateQueue(
        style: anotherQueue.style,
        spacing: anotherQueue.spacing,
        maxStackSize: anotherQueue.maxStackSize,
        dismissThreshold: anotherQueue.dismissThreshold,
      );

  NotificationQueue generateQueue({
    required final QueueStyle style,
    required final double spacing,
    required final int maxStackSize,
    required final int? dismissThreshold,
    final PendingIndicatorBuilder? queueIndicatorBuilder,
  }) {
    switch (this) {
      case topLeft:
        return TopLeftQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissThreshold: dismissThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case topCenter:
        return TopCenterQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissThreshold: dismissThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case topRight:
        return TopRightQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissThreshold: dismissThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case centerLeft:
        return CenterLeftQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissThreshold: dismissThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case centerRight:
        return CenterRightQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissThreshold: dismissThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case bottomLeft:
        return BottomLeftQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissThreshold: dismissThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case bottomCenter:
        return BottomCenterQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissThreshold: dismissThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case bottomRight:
        return BottomRightQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissThreshold: dismissThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
    }
  }

  AlignmentGeometry get alignment {
    switch (this) {
      case topLeft:
        return Alignment.topLeft;
      case topCenter:
        return Alignment.topCenter;
      case topRight:
        return Alignment.topRight;
      case centerLeft:
        return Alignment.centerLeft;
      case centerRight:
        return Alignment.centerRight;

      case bottomLeft:
        return Alignment.bottomLeft;
      case bottomCenter:
        return Alignment.bottomCenter;
      case bottomRight:
        return Alignment.bottomRight;
    }
  }
}

enum QueueCloseButtonBehaviour {
  always,
  onHover,
  never;
}

enum QueueRelocationBehaviour {
  /// LongPress drag relocates any notification to all possible positions.
  ///
  /// Undefined [QueuePosition]s will generate their [NotificationQueue] from
  /// the [NotificationManager]'s default [NotificationQueue] automatically.
  /// *CAUTION!!!* This can cause overlapping of notifications on
  /// smaller screens.
  allowAll,

  /// LongPress drag relocates any notification to any of the define positions
  allowDefined,

  /// Disable LongPress relocations.
  ///
  /// This is the default behavior.
  none;
}
