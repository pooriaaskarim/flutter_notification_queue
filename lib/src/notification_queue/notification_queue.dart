import 'dart:collection';

import 'package:flutter/material.dart';

import '../../flutter_notification_queue.dart';
import '../utils/utils.dart';

part 'type_defs.dart';
part 'queue_manager.dart';
part 'enums.dart';
part 'extensions.dart';

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
    required this.dismissalThreshold,
    required this.spacing,
    required this.style,
    required this.queueIndicatorBuilder,
  });
//todo(Pooriaaskarim): Docstrings
  final QueuePosition position;
  final int maxStackSize;

  /// Threshold in pixels for drag/long-press dismissal.
  final double dismissalThreshold;

  /// Spacing between queue notifications.
  final double spacing;

  /// Custom builder for the notification stack indicator.
  final PendingIndicatorBuilder? queueIndicatorBuilder;

  final QueueStyle style;

  QueueManager? _queueManager;

  QueueManager get manager => _queueManager ??= QueueManager(this);

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
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
  }) : super(position: QueuePosition.topLeft);
}

final class TopCenterQueue extends NotificationQueue {
  TopCenterQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
  }) : super(position: QueuePosition.topCenter);
}

final class TopRightQueue extends NotificationQueue {
  TopRightQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
  }) : super(position: QueuePosition.topRight);
}

final class CenterLeftQueue extends NotificationQueue {
  CenterLeftQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
  }) : super(position: QueuePosition.centerLeft);
}

// final class CenterQueue extends NotificationQueue {
//   CenterQueue({
//     super.style = const FlatQueueStyle(),
//     super.spacing = 4.0,
//     super.maxStackSize = 3,
//     super.queueIndicatorBuilder,
//     super.dismissalThreshold = 50.0,
//
//   }) : super(position: QueuePosition.center);
// }

final class CenterRightQueue extends NotificationQueue {
  CenterRightQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
  }) : super(position: QueuePosition.centerRight);
}

final class BottomLeftQueue extends NotificationQueue {
  BottomLeftQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
  }) : super(position: QueuePosition.bottomLeft);
}

final class BottomCenterQueue extends NotificationQueue {
  BottomCenterQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
  }) : super(position: QueuePosition.bottomCenter);
}

final class BottomRightQueue extends NotificationQueue {
  BottomRightQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
  }) : super(position: QueuePosition.bottomRight);
}
