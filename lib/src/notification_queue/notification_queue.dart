import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../flutter_notification_queue.dart';
import '../core/core.dart';
import '../utils/extensions.dart' show ExtendedStringFuntionalities;
import '../utils/utils.dart';

part 'styles.dart';
part 'queue_widget.dart';
part 'transitions.dart';
part 'type_defs.dart';

/// Configures queue layouts for each [QueuePosition].
///
/// Used in [FlutterNotificationQueue.configure] to configure queue layouts.
///
/// If no [NotificationQueue] is provided for a [QueuePosition],
/// defaults to constructor defaults.

@immutable
class NotificationQueue {
  const NotificationQueue({
    this.position = QueuePosition.topCenter,
    this.maxStackSize = 3,
    this.dragBehavior = const Dismiss(),
    this.longPressDragBehavior = const Disabled(),
    this.tapBehavior = const TapToDismiss(),
    this.closeButtonBehavior = const AlwaysVisible(),
    this.spacing = 4.0,
    this.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    this.style = const FlatQueueStyle(),
    this.queueIndicatorBuilder,
    this.transition = const SlideTransitionStrategy(),
    this.maxPendingSize,
    this.overflowStrategy = QueueOverflowStrategy.discardOldest,
    this.maxWidth,
    this.groupingBehavior = const QueueGroupingBehavior(),
  })  : assert(maxStackSize > 0, 'maxStackSize must be greater than 0'),
        assert(
          maxPendingSize == null || maxPendingSize > 0,
          'maxPendingSize must be greater than 0',
        ),
        assert(
          maxWidth == null || maxWidth > 0,
          'maxWidth must be greater than 0',
        );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is NotificationQueue && position == other.position;

  @override
  int get hashCode => position.hashCode;

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

  /// Behavior of notification on tap.
  ///
  /// Can be any of
  ///  + [TapToDismiss] — tapping closes the notification
  ///  + [TapToExpand]  — tapping toggles expanded/collapsed state
  ///  + [TapToAct]     — tapping fires a developer callback
  ///  + [TapDisabled]  — tapping produces no effect
  ///
  /// Individual [NotificationWidget]s can override this queue-level default
  /// by setting their own `tapBehavior` field.
  final TapBehavior tapBehavior;

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

  /// Maximum size of the pending notifications queue.
  /// If null, the pending queue is unbounded.
  final int? maxPendingSize;

  /// Strategy for handling queue overflow when [maxPendingSize] is reached.
  final QueueOverflowStrategy overflowStrategy;

  /// Custom maximum width of the notification card on desktop.
  /// If null, falls back to the default responsive width constraints.
  final double? maxWidth;

  /// Configuration for notification grouping/bundling.
  final QueueGroupingBehavior groupingBehavior;

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
    switch (position) {
      case QueuePosition.topCenter:
      case QueuePosition.topLeft:
      case QueuePosition.topRight:
        return MainAxisAlignment.start;
      case QueuePosition.centerLeft:
      case QueuePosition.centerRight:
        return MainAxisAlignment.center;
      case QueuePosition.bottomCenter:
      case QueuePosition.bottomLeft:
      case QueuePosition.bottomRight:
        return MainAxisAlignment.end;
    }
  }

  CrossAxisAlignment get crossAxisAlignment {
    switch (position) {
      case QueuePosition.topCenter:
      case QueuePosition.bottomCenter:
        return CrossAxisAlignment.center;
      case QueuePosition.topLeft:
      case QueuePosition.bottomLeft:
      case QueuePosition.centerLeft:
        return CrossAxisAlignment.start;
      case QueuePosition.topRight:
      case QueuePosition.bottomRight:
      case QueuePosition.centerRight:
        return CrossAxisAlignment.end;
    }
  }

  VerticalDirection get verticalDirection {
    switch (position) {
      case QueuePosition.topCenter:
      case QueuePosition.topLeft:
      case QueuePosition.topRight:
      case QueuePosition.centerLeft:
      case QueuePosition.centerRight:
        return VerticalDirection.down;
      case QueuePosition.bottomCenter:
      case QueuePosition.bottomLeft:
      case QueuePosition.bottomRight:
        return VerticalDirection.up;
    }
  }

  @override
  String toString() => '${position.toString().capitalize}Queue';
}
