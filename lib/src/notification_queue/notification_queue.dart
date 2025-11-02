import 'dart:collection';

import 'package:flutter/material.dart';

import '../../flutter_notification_queue.dart';
import '../notification_wrapper/notification_manager/notification_manager.dart';
import '../notification_wrapper/overlay_manager/overlay_manager.dart';
import '../utils/logger.dart';

part 'extensions.dart';

part 'queue_widget.dart';

// part 'queue_manager.dart';

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
    required this.dragBehavior,
    required this.longPressDragBehavior,
    required this.closeButtonBehavior,
    required this.spacing,
    required this.margin,
    required this.style,
    required this.queueIndicatorBuilder,
  })  : assert(maxStackSize > 0, 'maxStackSize must be greater than 0'),
        assert(
          !(longPressDragBehavior is Relocate && dragBehavior is Relocate),
          'dragBehavior and longPressDragBehavior cannot be both of type'
          ' RelocateNotificationBehavior at the same time.',
        ) {
    for (final behavior in [longPressDragBehavior, dragBehavior]) {
      if (behavior is Relocate) {
        final relocationBehavior = behavior as Relocate;
        relocationBehavior.positions.add(position);
        groupPositions.addAll(relocationBehavior.positions);
      } else {
        groupPositions.add(position);
      }
    }
  }

  final QueuePosition position;

  /// Maximum number of notifications shown at a given time.
  ///
  /// Must be greater than 0!
  final int maxStackSize;

  /// Behavior of notification on LongPress dragging.
  ///
  /// Can be any of
  ///  + [Relocate]
  ///  + [Dismiss]
  ///  + [Disabled]
  final LongPressDragBehavior longPressDragBehavior;

  /// Behavior of notification on Drag.
  ///
  /// Can be any of
  ///  + [Relocate]
  ///  + [Dismiss]
  ///  + [Disabled]
  final DragBehavior dragBehavior;

  final Set<QueuePosition> groupPositions = {};

  /// Spacing between queue notifications.
  final double spacing;

  /// Margin around queue notifications.
  final EdgeInsetsGeometry margin;

  /// Notification close button behavior.
  final QueueCloseButtonBehavior closeButtonBehavior;

  /// Custom builder for the notification stack indicator.
  final QueueIndicatorBuilder? queueIndicatorBuilder;

  /// Looks and feels of [NotificationWidget]s inside the queue
  final QueueStyle style;

  QueueWidget? _queueWidget;

  QueueWidget get widget {
    if (_queueWidget != null) {
      return _queueWidget!;
    } else {}
    _queueWidget = QueueWidget._(
      parentQueue: this,
      key: GlobalKey<QueueWidgetState>(),
    );
    OverlayManager.instance.show(
      toString(),
      OverlayEntryData(
        builder: (final context) => _queueWidget!,
        position: AlignedPosition(widget.parentQueue.position.alignment),
      ),
    );
    return _queueWidget!;
  }

  // QueueManager? _queueManager;
  //
  // QueueManager get manager => _queueManager ??= QueueManager(this);

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
    super.dragBehavior = const Dismiss(),
    super.longPressDragBehavior = const Disabled(),
    super.closeButtonBehavior = QueueCloseButtonBehavior.always,
  }) : super(position: QueuePosition.topLeft);
}

final class TopCenterQueue extends NotificationQueue {
  TopCenterQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehavior = const Dismiss(),
    super.longPressDragBehavior = const Disabled(),
    super.closeButtonBehavior = QueueCloseButtonBehavior.always,
  }) : super(position: QueuePosition.topCenter);
}

final class TopRightQueue extends NotificationQueue {
  TopRightQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehavior = const Dismiss(),
    super.longPressDragBehavior = const Disabled(),
    super.closeButtonBehavior = QueueCloseButtonBehavior.always,
  }) : super(position: QueuePosition.topRight);
}

final class CenterLeftQueue extends NotificationQueue {
  CenterLeftQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehavior = const Dismiss(),
    super.longPressDragBehavior = const Disabled(),
    super.closeButtonBehavior = QueueCloseButtonBehavior.always,
  }) : super(position: QueuePosition.centerLeft);
}

final class CenterRightQueue extends NotificationQueue {
  CenterRightQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehavior = const Dismiss(),
    super.longPressDragBehavior = const Disabled(),
    super.closeButtonBehavior = QueueCloseButtonBehavior.always,
  }) : super(position: QueuePosition.centerRight);
}

final class BottomLeftQueue extends NotificationQueue {
  BottomLeftQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehavior = const Dismiss(),
    super.longPressDragBehavior = const Disabled(),
    super.closeButtonBehavior = QueueCloseButtonBehavior.always,
  }) : super(position: QueuePosition.bottomLeft);
}

final class BottomCenterQueue extends NotificationQueue {
  BottomCenterQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehavior = const Dismiss(),
    super.longPressDragBehavior = const Disabled(),
    super.closeButtonBehavior = QueueCloseButtonBehavior.always,
  }) : super(position: QueuePosition.bottomCenter);
}

final class BottomRightQueue extends NotificationQueue {
  BottomRightQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehavior = const Dismiss(),
    super.longPressDragBehavior = const Disabled(),
    super.closeButtonBehavior = QueueCloseButtonBehavior.always,
  }) : super(position: QueuePosition.bottomRight);
}
