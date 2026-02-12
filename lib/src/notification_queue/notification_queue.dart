import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:logd/logd.dart';

import '../../flutter_notification_queue.dart';
import '../core/core.dart';

part 'queue_widget.dart';
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
/// Used in [FlutterNotificationQueue.initialize] to configure queue layouts.
///
/// If no [NotificationQueue] is provided for a [QueuePosition],
/// defaults to that position's constructor defaults.

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

  final _pendingNotifications = Queue<NotificationWidget>();
  final _activeNotifications = ValueNotifier(
    LinkedHashSet<NotificationWidget>(
      equals: (final n1, final n2) => n1.id == n2.id,
      hashCode: (final n) => n.id.hashCode,
    ),
  );

  LinkedHashSet<NotificationWidget> _createSet() =>
      LinkedHashSet<NotificationWidget>(
        equals: (final n1, final n2) => n1.id == n2.id,
        hashCode: (final n) => n.id.hashCode,
      );

  void queue(final NotificationWidget notification) {
    final b = _logger.debugBuffer
      ?..writeAll(['Queueing Notification: $notification']);

    if (!notification.channel.enabled) {
      b?.writeln('Channel ${notification.channel.name} is disabled. Skipping.');
      b?.sink();
      return;
    }

    // 1. Check Active: Update in place if exists (preserve order)
    final activeSet = _activeNotifications.value;
    // We can't efficiently check "contains" with custom equality without
    // iterating anyway
    // if we want to replace.
    // But let's check if we need to update first to avoid unnecessary allocs.
    final isActiveUpdate = activeSet.any((final n) => n.id == notification.id);
    if (isActiveUpdate) {
      final newSet = LinkedHashSet<NotificationWidget>(
        equals: (final n1, final n2) => n1.id == n2.id,
        hashCode: (final n) => n.id.hashCode,
      );
      for (final n in activeSet) {
        if (n.id == notification.id) {
          newSet.add(notification);
        } else {
          newSet.add(n);
        }
      }
      _activeNotifications.value = newSet;
      b?.writeln('Updated active notification.');
      b?.sink();
      return;
    }

    // 2. Check Pending: Update in place if exists (preserve order)
    bool isPendingUpdate = false;
    // Queue doesn't support indexed access/replace easily.
    // We rebuild it.
    final tempQueue = Queue<NotificationWidget>();
    while (_pendingNotifications.isNotEmpty) {
      final n = _pendingNotifications.removeFirst();
      if (n.id == notification.id) {
        tempQueue.add(notification);
        isPendingUpdate = true;
      } else {
        tempQueue.add(n);
      }
    }
    _pendingNotifications.addAll(tempQueue);

    if (isPendingUpdate) {
      b?.writeln('Updated pending notification.');
      b?.sink();
      return;
    }

    // 3. New Notification
    final wasEmpty =
        _pendingNotifications.isEmpty && _activeNotifications.value.isEmpty;
    _pendingNotifications.add(notification);
    if (wasEmpty) {
      final _ = _widget; // Force creation if this is the first
    }
    _processPending();
    b?.sink();
  }

  void dismiss(final NotificationWidget notification) {
    final b = _logger.debugBuffer
      ?..writeAll(['Dismissing Notification: $notification']);
    final removed = _activeNotifications.value.remove(notification);
    if (removed) {
      _activeNotifications.value = _createSet()
        ..addAll(_activeNotifications.value);
    } else {
      _pendingNotifications.removeWhere((final n) => n.id == notification.id);
    }
    _processPending(); // Fill from pending if space now
    _safeDispose();
    b?.sink();
  }

  void bringToFront() {
    QueueCoordinator.instance.bringToFront(position);
  }

  NotificationWidget? relocate(
    final NotificationWidget notification,
    final QueuePosition newPosition,
  ) {
    final b = _logger.debugBuffer
      ?..writeAll([
        'Relocating Notification: $notification',
        'To: $newPosition',
      ]);
    final removedFromActive = _activeNotifications.value.remove(notification);
    _pendingNotifications.removeWhere((final n) => n.id == notification.id);
    final removedFromPending = !removedFromActive &&
        _pendingNotifications
            .where((final n) => n.id == notification.id)
            .isEmpty;

    NotificationWidget? newNotification;
    if (removedFromActive || removedFromPending) {
      final newQueue = ConfigurationManager.instance.getQueue(newPosition);
      newNotification = notification.copyWith(newPosition);
      newQueue.queue(newNotification);
      if (removedFromActive) {
        _activeNotifications.value = _createSet()
          ..addAll(_activeNotifications.value);
      }
      _processPending(); // Fill from pending if space now
    } else {
      b?.writeAll(['Notification Not Found.']);
    }
    _safeDispose();
    b?.sink();
    return newNotification;
  }

  void _processPending() {
    final b = _logger.debugBuffer;
    while (_pendingNotifications.isNotEmpty &&
        _activeNotifications.value.length < maxStackSize) {
      final notification = _pendingNotifications.removeFirst();
      _activeNotifications.value.add(notification);
      _activeNotifications.value = _createSet()
        ..addAll(_activeNotifications.value);
    }

    // If we have active notifications, ensure the queue is active in the
    // coordinator
    if (_activeNotifications.value.isNotEmpty) {
      QueueCoordinator.instance.activateQueue(this);
    }

    b?.sink();
  }

  bool _safeDispose() {
    final b = _logger.debugBuffer;
    if (_pendingNotifications.isEmpty && _activeNotifications.value.isEmpty) {
      b?.writeAll(['No pending or active. Deactivating queue.']);
      QueueCoordinator.instance.deactivateQueue(position);
      // We don't null out _cachedWidget anymore because we might reuse it.
      // But if we want to save memory, we could. For now, let's keep it
      // consistent with Phase 1 fix.
      _cachedWidget = null;
      return true;
    }
    return false;
  }

  QueueWidget? _cachedWidget;
  static final _logger = Logger.get('fnq.Queue');

  /// The widget that renders this queue's notifications.
  QueueWidget get widget => _widget;

  QueueWidget get _widget {
    final b = _logger.debugBuffer;
    if (_cachedWidget != null) {
      b
        ?..writeln('QueueWidget already exists.')
        ..sink();
      return _cachedWidget!;
    } else {
      b?.writeln('No QueueWidget exists, creating... .');
      _cachedWidget = QueueWidget._(
        parentQueue: this,
        key: GlobalKey<QueueWidgetState>(),
      );
      return _cachedWidget!;
    }
  }

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
