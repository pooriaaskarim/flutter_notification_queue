import 'dart:collection';

import 'package:flutter/material.dart';

import '../../flutter_notification_queue.dart';
import '../utils/utils.dart';

part 'type_defs.dart';
part 'queue_manager.dart';
part 'extensions.dart';

///  [NotificationQueue]s based on [QueuePosition].
///
/// - [TopStartQueue]
/// - [TopCenterQueue]
/// - [TopEndQueue]
/// - [CenterStartQueue]
/// - [CenterQueue]
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
    required this.margin,
    required this.spacing,
    required this.opacity,
    required this.elevation,
    required this.showCloseButton,
    required this.queueIndicatorBuilder,
  });
//todo(Pooriaaskarim): Docstrings
  final QueuePosition position;
  final EdgeInsets? margin;
  final double spacing;
  final int maxStackSize;

  /// Threshold in pixels for drag/long-press dismissal.
  final double dismissalThreshold;

  /// Custom builder for the notification stack indicator.
  final PendingIndicatorBuilder? queueIndicatorBuilder;

  /// Default opacity for notification background.
  final double opacity;

  /// Default elevation for notification cards.
  final double elevation;

  /// Whether to show close button.
  final bool showCloseButton;

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
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity = 0.8,
    super.elevation = 3,
    super.showCloseButton = true,
  }) : super(position: QueuePosition.topStart);
}

final class TopCenterQueue extends NotificationQueue {
  TopCenterQueue({
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity = 0.8,
    super.elevation = 3,
    super.showCloseButton = true,
  }) : super(position: QueuePosition.topCenter);
}

final class TopEndQueue extends NotificationQueue {
  TopEndQueue({
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity = 0.8,
    super.elevation = 3,
    super.showCloseButton = true,
  }) : super(position: QueuePosition.topEnd);
}

final class CenterStartQueue extends NotificationQueue {
  CenterStartQueue({
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity = 0.8,
    super.elevation = 3,
    super.showCloseButton = true,
  }) : super(position: QueuePosition.centerStart);
}

final class CenterQueue extends NotificationQueue {
  CenterQueue({
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity = 0.8,
    super.elevation = 3,
    super.showCloseButton = true,
  }) : super(position: QueuePosition.center);
}

final class CenterEndQueue extends NotificationQueue {
  CenterEndQueue({
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity = 0.8,
    super.elevation = 3,
    super.showCloseButton = true,
  }) : super(position: QueuePosition.centerEnd);
}

final class BottomStartQueue extends NotificationQueue {
  BottomStartQueue({
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity = 0.8,
    super.elevation = 3,
    super.showCloseButton = true,
  }) : super(position: QueuePosition.bottomStart);
}

final class BottomCenterQueue extends NotificationQueue {
  BottomCenterQueue({
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity = 0.8,
    super.elevation = 3,
    super.showCloseButton = true,
  }) : super(position: QueuePosition.bottomCenter);
}

final class BottomEndQueue extends NotificationQueue {
  BottomEndQueue({
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity = 0.8,
    super.elevation = 3,
    super.showCloseButton = true,
  }) : super(position: QueuePosition.bottomEnd);
}
