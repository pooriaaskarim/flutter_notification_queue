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
    required this.dismissThreshold,
    required this.relocationThreshold,
    required this.closeButtonBehaviour,
    required this.spacing,
    required this.margin,
    required this.style,
    required this.queueIndicatorBuilder,
  });
//todo(Pooriaaskarim): Docstrings
  final QueuePosition position;
  final int maxStackSize;

  /// Pixels left from screen edge to dismiss notification on *drag*.
  ///
  /// Set to null to disable drag dismiss. This also would cause queue
  /// notifications to bypass [closeButtonBehaviour] and always show
  /// close button.
  final int? dismissThreshold;

  /// Pixels left from screen edge to relocate notification on *LongPress*.
  ///
  /// Set to null to disable longPress relocation.
  final int? relocationThreshold;

  /// Spacing between queue notifications.
  final double spacing;

  /// Margin around queue notifications.
  final EdgeInsetsGeometry margin;

  /// Notification close button behaviour.
  final QueueCloseButtonBehaviour closeButtonBehaviour;

  /// Custom builder for the notification stack indicator.
  final PendingIndicatorBuilder? queueIndicatorBuilder;

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

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is NotificationQueue && other.position == position;
  }

  @override
  int get hashCode => position.hashCode;
}

final class TopLeftQueue extends NotificationQueue {
  TopLeftQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissThreshold = 50,
    super.relocationThreshold = 50,
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
    super.dismissThreshold = 50,
    super.relocationThreshold = 50,
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
    super.dismissThreshold = 50,
    super.relocationThreshold = 50,
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
    super.dismissThreshold = 50,
    super.relocationThreshold = 50,
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
    super.dismissThreshold = 50,
    super.relocationThreshold = 50,
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
    super.dismissThreshold = 50,
    super.relocationThreshold = 50,
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
    super.dismissThreshold = 50,
    super.relocationThreshold = 50,
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
    super.dismissThreshold = 50,
    super.relocationThreshold = 50,
    super.closeButtonBehaviour = QueueCloseButtonBehaviour.always,
  }) : super(position: QueuePosition.bottomRight);
}
