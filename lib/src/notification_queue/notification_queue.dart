import 'dart:collection';

import 'package:flutter/material.dart';

import '../../flutter_notification_queue.dart';

part 'enums.dart';
part 'extensions.dart';
part 'queue_manager.dart';
part 'type_defs.dart';
part 'styles.dart';

///  [NotificationQueue]s based on [QueuePosition].
///
/// - [TopLeftQueue]
/// - [TopCenterQueue]
/// - [TopRightQueue]
/// - [CenterLeftQueue]
/// - [CenterRightQueue]
/// - [BottomLeftQueue]
/// - [BottomCenterQueue]
/// - [BottomRightQueue].
///
/// Used Only inside
/// ```dart
/// NotificationManager.instance.configureQueues(Set<Queue>)
/// ```
/// to configure Queue layouts.
///
/// If no [NotificationQueue] is provided for a [QueuePosition],
/// defaults to a that positions constructor defaults.

sealed class NotificationQueue {
  NotificationQueue({
    required this.position,
    required this.maxStackSize,
    required this.dragBehaviour,
    required this.longPressDragBehaviour,
    required this.closeButtonBehaviour,
    required this.spacing,
    required this.margin,
    required this.style,
    required this.queueIndicatorBuilder,
  })  : assert(maxStackSize > 0, 'maxStackSize must be greater than 0'),
        assert(
          !(longPressDragBehaviour is RelocateNotificationBehaviour &&
              dragBehaviour is RelocateNotificationBehaviour),
          'dragBehaviour and longPressDragBehaviour cannot be both of type'
          ' RelocateNotificationBehaviour at the same time',
        ) {
    if (longPressDragBehaviour is RelocateLongPressDragBehaviour) {
      (longPressDragBehaviour as RelocateLongPressDragBehaviour)
          .positions
          .add(position);
    }
    if (dragBehaviour is RelocateDragBehaviour) {
      (dragBehaviour as RelocateDragBehaviour).positions.add(position);
    }
  }

  // factory NotificationQueue.fromPosition(
  //   final QueuePosition position, {
  //   required final int maxStackSize,
  //   required final QueueDismissBehaviour dismissBehaviour,
  //   required final QueueRelocationBehaviour relocationBehaviour,
  //   required final QueueCloseButtonBehaviour closeButtonBehaviour,
  //   required final double spacing,
  //   required final EdgeInsetsGeometry margin,
  //   required final QueueStyle style,
  //   required final QueueIndicatorBuilder? queueIndicatorBuilder,
  // }) =>
  //     switch (position) {
  //       QueuePosition.topLeft => TopLeftQueue(
  //           relocationBehaviour: relocationBehaviour,
  //           queueIndicatorBuilder: queueIndicatorBuilder,
  //           closeButtonBehaviour: closeButtonBehaviour,
  //           dismissBehaviour: dismissBehaviour,
  //           margin: margin,
  //           maxStackSize: maxStackSize,
  //           spacing: spacing,
  //           style: style,
  //         ),
  //       QueuePosition.topCenter => TopCenterQueue(
  //           relocationBehaviour: relocationBehaviour,
  //           queueIndicatorBuilder: queueIndicatorBuilder,
  //           closeButtonBehaviour: closeButtonBehaviour,
  //           dismissBehaviour: dismissBehaviour,
  //           margin: margin,
  //           maxStackSize: maxStackSize,
  //           spacing: spacing,
  //           style: style,
  //         ),
  //       QueuePosition.topRight => TopRightQueue(
  //           relocationBehaviour: relocationBehaviour,
  //           queueIndicatorBuilder: queueIndicatorBuilder,
  //           closeButtonBehaviour: closeButtonBehaviour,
  //           dismissBehaviour: dismissBehaviour,
  //           margin: margin,
  //           maxStackSize: maxStackSize,
  //           spacing: spacing,
  //           style: style,
  //         ),
  //       QueuePosition.centerLeft => CenterLeftQueue(
  //           relocationBehaviour: relocationBehaviour,
  //           queueIndicatorBuilder: queueIndicatorBuilder,
  //           closeButtonBehaviour: closeButtonBehaviour,
  //           dismissBehaviour: dismissBehaviour,
  //           margin: margin,
  //           maxStackSize: maxStackSize,
  //           spacing: spacing,
  //           style: style,
  //         ),
  //       QueuePosition.centerRight => CenterRightQueue(
  //           relocationBehaviour: relocationBehaviour,
  //           queueIndicatorBuilder: queueIndicatorBuilder,
  //           closeButtonBehaviour: closeButtonBehaviour,
  //           dismissBehaviour: dismissBehaviour,
  //           margin: margin,
  //           maxStackSize: maxStackSize,
  //           spacing: spacing,
  //           style: style,
  //         ),
  //       QueuePosition.bottomLeft => BottomLeftQueue(
  //           relocationBehaviour: relocationBehaviour,
  //           queueIndicatorBuilder: queueIndicatorBuilder,
  //           closeButtonBehaviour: closeButtonBehaviour,
  //           dismissBehaviour: dismissBehaviour,
  //           margin: margin,
  //           maxStackSize: maxStackSize,
  //           spacing: spacing,
  //           style: style,
  //         ),
  //       QueuePosition.bottomCenter => BottomCenterQueue(
  //           relocationBehaviour: relocationBehaviour,
  //           queueIndicatorBuilder: queueIndicatorBuilder,
  //           closeButtonBehaviour: closeButtonBehaviour,
  //           dismissBehaviour: dismissBehaviour,
  //           margin: margin,
  //           maxStackSize: maxStackSize,
  //           spacing: spacing,
  //           style: style,
  //         ),
  //       QueuePosition.bottomRight => BottomRightQueue(
  //           relocationBehaviour: relocationBehaviour,
  //           queueIndicatorBuilder: queueIndicatorBuilder,
  //           closeButtonBehaviour: closeButtonBehaviour,
  //           dismissBehaviour: dismissBehaviour,
  //           margin: margin,
  //           maxStackSize: maxStackSize,
  //           spacing: spacing,
  //           style: style,
  //         ),
  //     };

  /// Position of the [NotificationQueue] on the screen.
  ///
  /// Can be any of
  ///  + [QueuePosition.topLeft]
  ///  + [QueuePosition.topCenter]
  ///  + [QueuePosition.topRight]
  ///  + [QueuePosition.centerLeft]
  ///  + [QueuePosition.centerRight]
  ///  + [QueuePosition.bottomLeft]
  ///  + [QueuePosition.bottomCenter]
  ///  + [QueuePosition.bottomRight]
  final QueuePosition position;

  /// Maximum number of notifications shown at a given time.
  ///
  /// Must be greater than 0!
  final int maxStackSize;

  /// Behaviour of notification on LongPress dragging.
  ///
  /// Can be any of
  ///  + [RelocateLongPressDragBehaviour]
  ///  + [DismissLongPressDragBehaviour]
  ///  + [DisabledLongPressDragBehaviour]
  final LongPressDragBehaviour longPressDragBehaviour;

  /// Behaviour of notification on Drag.
  ///
  /// Can be any of
  ///  + [RelocateDragBehaviour]
  ///  + [DismissDragBehaviour]
  ///  + [DisabledDragBehaviour]
  final DragBehaviour dragBehaviour;

  /// Spacing between queue notifications.
  final double spacing;

  /// Margin around queue notifications.
  final EdgeInsetsGeometry margin;

  /// Notification close button behaviour.
  final QueueCloseButtonBehaviour closeButtonBehaviour;

  /// Custom builder for the notification stack indicator.
  final QueueIndicatorBuilder? queueIndicatorBuilder;

  /// Looks and feels of [NotificationWidget]s inside the queue
  final QueueStyle style;

  QueueManager? _queueManager;

  QueueManager get manager => _queueManager ??= QueueManager(this);

  MainAxisAlignment get mainAxisAlignment {
    switch (this) {
      case TopCenterQueue():
      case TopLeftQueue():
      case TopRightQueue():
        return MainAxisAlignment.start;
      case CenterLeftQueue():
      case CenterRightQueue():
        return MainAxisAlignment.center;
      case BottomCenterQueue():
      case BottomLeftQueue():
      case BottomRightQueue():
        return MainAxisAlignment.end;
    }
  }

  CrossAxisAlignment get crossAxisAlignment {
    switch (this) {
      case TopCenterQueue():
      case BottomCenterQueue():
        return CrossAxisAlignment.center;
      case TopLeftQueue():
      case BottomLeftQueue():
      case CenterLeftQueue():
        return CrossAxisAlignment.start;
      case TopRightQueue():
      case BottomRightQueue():
      case CenterRightQueue():
        return CrossAxisAlignment.end;
    }
  }

  VerticalDirection get verticalDirection {
    switch (this) {
      case TopCenterQueue():
      case TopLeftQueue():
      case TopRightQueue():
      case CenterLeftQueue():
      case CenterRightQueue():
        return VerticalDirection.down;
      case BottomCenterQueue():
      case BottomLeftQueue():
      case BottomRightQueue():
        return VerticalDirection.up;
    }
  }

  Offset get slideTransitionOffset {
    switch (this) {
      case TopLeftQueue():
      case CenterLeftQueue():
      case BottomLeftQueue():
        return const Offset(-1, 0);
      case TopCenterQueue():
        return const Offset(0, -1);

      case BottomCenterQueue():
        return const Offset(0, 1);
      case TopRightQueue():
      case CenterRightQueue():
      case BottomRightQueue():
        return const Offset(1, 0);
    }
  }

  @override
  String toString() => '$runtimeType';
}

final class TopLeftQueue extends NotificationQueue {
  TopLeftQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehaviour = const DismissDragBehaviour(),
    super.longPressDragBehaviour = const DisabledLongPressDragBehaviour(),
    super.closeButtonBehaviour = QueueCloseButtonBehaviour.always,
  }) : super(position: QueuePosition.topLeft);
}

final class TopCenterQueue extends NotificationQueue {
  TopCenterQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehaviour = const DismissDragBehaviour(),
    super.longPressDragBehaviour = const DisabledLongPressDragBehaviour(),
    super.closeButtonBehaviour = QueueCloseButtonBehaviour.always,
  }) : super(position: QueuePosition.topCenter);
}

final class TopRightQueue extends NotificationQueue {
  TopRightQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehaviour = const DismissDragBehaviour(),
    super.longPressDragBehaviour = const DisabledLongPressDragBehaviour(),
    super.closeButtonBehaviour = QueueCloseButtonBehaviour.always,
  }) : super(position: QueuePosition.topRight);
}

final class CenterLeftQueue extends NotificationQueue {
  CenterLeftQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehaviour = const DismissDragBehaviour(),
    super.longPressDragBehaviour = const DisabledLongPressDragBehaviour(),
    super.closeButtonBehaviour = QueueCloseButtonBehaviour.always,
  }) : super(position: QueuePosition.centerLeft);
}

final class CenterRightQueue extends NotificationQueue {
  CenterRightQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehaviour = const DismissDragBehaviour(),
    super.longPressDragBehaviour = const DisabledLongPressDragBehaviour(),
    super.closeButtonBehaviour = QueueCloseButtonBehaviour.always,
  }) : super(position: QueuePosition.centerRight);
}

final class BottomLeftQueue extends NotificationQueue {
  BottomLeftQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehaviour = const DismissDragBehaviour(),
    super.longPressDragBehaviour = const DisabledLongPressDragBehaviour(),
    super.closeButtonBehaviour = QueueCloseButtonBehaviour.always,
  }) : super(position: QueuePosition.bottomLeft);
}

final class BottomCenterQueue extends NotificationQueue {
  BottomCenterQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehaviour = const DismissDragBehaviour(),
    super.longPressDragBehaviour = const DisabledLongPressDragBehaviour(),
    super.closeButtonBehaviour = QueueCloseButtonBehaviour.always,
  }) : super(position: QueuePosition.bottomCenter);
}

final class BottomRightQueue extends NotificationQueue {
  BottomRightQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehaviour = const DismissDragBehaviour(),
    super.longPressDragBehaviour = const DisabledLongPressDragBehaviour(),
    super.closeButtonBehaviour = QueueCloseButtonBehaviour.always,
  }) : super(position: QueuePosition.bottomRight);
}
