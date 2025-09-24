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
/// - [TopStartQueue]
/// - [TopCenterQueue]
/// - [TopEndQueue]
/// - [CenterStartQueue]
/// - [CenterEndQueue]
/// - [BottomStartQueue]
/// - [BottomCenterQueue]
/// - [BottomEndQueue].
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

final class TopStartQueue extends NotificationQueue {
  TopStartQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
  }) : super(position: QueuePosition.topStart);
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

final class TopEndQueue extends NotificationQueue {
  TopEndQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
  }) : super(position: QueuePosition.topEnd);
}

final class CenterStartQueue extends NotificationQueue {
  CenterStartQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
  }) : super(position: QueuePosition.centerStart);
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

final class CenterEndQueue extends NotificationQueue {
  CenterEndQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
  }) : super(position: QueuePosition.centerEnd);
}

final class BottomStartQueue extends NotificationQueue {
  BottomStartQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
  }) : super(position: QueuePosition.bottomStart);
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

final class BottomEndQueue extends NotificationQueue {
  BottomEndQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
  }) : super(position: QueuePosition.bottomEnd);
}
