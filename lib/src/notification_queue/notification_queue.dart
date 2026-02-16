import 'dart:collection';

import 'package:flutter/material.dart';

import '../../flutter_notification_queue.dart';
import '../utils/extensions.dart' show ExtendedStringFuntionalities;

part 'styles.dart';
part 'queue_widget.dart';
part 'transitions.dart';
part 'type_defs.dart';

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
/// Used in [FlutterNotificationQueue.initialize] to configure queue layouts.
///
/// If no [NotificationQueue] is provided for a [QueuePosition],
/// defaults to that position's constructor defaults.

sealed class NotificationQueue {
  const NotificationQueue({
    required this.position,
    required this.maxStackSize,
    required this.dragBehavior,
    required this.longPressDragBehavior,
    required this.closeButtonBehavior,
    required this.spacing,
    required this.margin,
    required this.style,
    required this.queueIndicatorBuilder,
    required this.transition,
  }) : assert(maxStackSize > 0, 'maxStackSize must be greater than 0');

  factory NotificationQueue.defaultQueue({
    final QueuePosition position = QueuePosition.topCenter,
    final int maxStackSize = 3,
    final DragBehavior dragBehavior = const Disabled(),
    final LongPressDragBehavior longPressDragBehavior = const Disabled(),
    final QueueCloseButtonBehavior closeButtonBehavior =
        QueueCloseButtonBehavior.always,
    final double spacing = 4.0,
    final EdgeInsetsGeometry margin =
        const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    final QueueStyle style = const FilledQueueStyle(),
    final QueueIndicatorBuilder? queueIndicatorBuilder,
    final NotificationTransition? transition,
  }) =>
      position.generateQueue(
        maxStackSize: maxStackSize,
        dragBehavior: dragBehavior,
        longPressDragBehavior: longPressDragBehavior,
        closeButtonBehavior: closeButtonBehavior,
        spacing: spacing,
        style: style,
        margin: margin,
        queueIndicatorBuilder: queueIndicatorBuilder,
        transition: transition,
      );

  // NOTE: Assertions that depend on runtime checks of concrete types or complex
  // logic within const constructors are limited. We removed the complex init
  // logic that was populating groupPositions. Now the *Group* definition logic
  // must move elsewhere or be handled differently if we want const here.
  //
  // For now, let's keep it simple. The grouping logic was:
  // "If behavior is Relocate, add this position to the behavior's group."
  //
  // But behaviors are now const too. Relocate holds a Set<QueuePosition>.
  // We can't mutate that set in a const constructor.
  // This implies Relocate.to({...}) must explicitly include the source position
  // OR the coordinator handles the grouping logic at runtime.
  //
  // Let's defer grouping logic to the Coordinator or validation phase.

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

  /// Entrance/Exit animation strategy.
  final NotificationTransition transition;

  //
  // /// The widget that renders this queue's notifications.
  // // The widget is now managed by the Coordinator via QueueState/builder?
  // // Or simply, this getter returns a new QueueWidget instance which connects to
  // // the coordinator?
  // //
  // // The previous design had `QueueWidget get widget => _widget;` holding a cached instance.
  // // Now we can return a fresh widget that *uses* data from the coordinator.
  // // Since QueueWidget is stateful, the key is important.
  // //
  // // We can use a unique key based on position.
  // Widget get widget => QueueWidget(key: ValueKey(position), queue: this);

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

  @override
  String toString() => '${position.toString().capitalize}Queue';
}

final class TopLeftQueue extends NotificationQueue {
  const TopLeftQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehavior = const Dismiss(),
    super.longPressDragBehavior = const Disabled(),
    super.closeButtonBehavior = QueueCloseButtonBehavior.always,
    super.transition = const SlideTransitionStrategy(),
  }) : super(position: QueuePosition.topLeft);
}

final class TopCenterQueue extends NotificationQueue {
  const TopCenterQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehavior = const Dismiss(),
    super.longPressDragBehavior = const Disabled(),
    super.closeButtonBehavior = QueueCloseButtonBehavior.always,
    super.transition = const SlideTransitionStrategy(),
  }) : super(position: QueuePosition.topCenter);
}

final class TopRightQueue extends NotificationQueue {
  const TopRightQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehavior = const Dismiss(),
    super.longPressDragBehavior = const Disabled(),
    super.closeButtonBehavior = QueueCloseButtonBehavior.always,
    super.transition = const SlideTransitionStrategy(),
  }) : super(position: QueuePosition.topRight);
}

final class CenterLeftQueue extends NotificationQueue {
  const CenterLeftQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehavior = const Dismiss(),
    super.longPressDragBehavior = const Disabled(),
    super.closeButtonBehavior = QueueCloseButtonBehavior.always,
    super.transition = const SlideTransitionStrategy(),
  }) : super(position: QueuePosition.centerLeft);
}

final class CenterRightQueue extends NotificationQueue {
  const CenterRightQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehavior = const Dismiss(),
    super.longPressDragBehavior = const Disabled(),
    super.closeButtonBehavior = QueueCloseButtonBehavior.always,
    super.transition = const SlideTransitionStrategy(),
  }) : super(position: QueuePosition.centerRight);
}

final class BottomLeftQueue extends NotificationQueue {
  const BottomLeftQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehavior = const Dismiss(),
    super.longPressDragBehavior = const Disabled(),
    super.closeButtonBehavior = QueueCloseButtonBehavior.always,
    super.transition = const SlideTransitionStrategy(),
  }) : super(position: QueuePosition.bottomLeft);
}

final class BottomCenterQueue extends NotificationQueue {
  const BottomCenterQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehavior = const Dismiss(),
    super.longPressDragBehavior = const Disabled(),
    super.closeButtonBehavior = QueueCloseButtonBehavior.always,
    super.transition = const SlideTransitionStrategy(),
  }) : super(position: QueuePosition.bottomCenter);
}

final class BottomRightQueue extends NotificationQueue {
  const BottomRightQueue({
    super.style = const FlatQueueStyle(),
    super.spacing = 4.0,
    super.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dragBehavior = const Dismiss(),
    super.longPressDragBehavior = const Disabled(),
    super.closeButtonBehavior = QueueCloseButtonBehavior.always,
    super.transition = const SlideTransitionStrategy(),
  }) : super(position: QueuePosition.bottomRight);
}
