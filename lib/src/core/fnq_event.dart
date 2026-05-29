part of 'core.dart';

// ── Dismiss reason ─────────────────────────────────────────────────────────

/// Describes why a [NotificationWidget] was dismissed.
enum DismissReason {
  /// The notification's auto-dismiss timer expired.
  timeout,

  /// The user swiped the notification away via a drag gesture.
  userSwipe,

  /// The user tapped the notification and the queue's [TapToDismiss] behavior
  /// triggered the dismissal.
  userTap,

  /// The notification was dismissed programmatically via
  /// [NotificationWidget.dismiss].
  programmatic,
}

// ── Event hierarchy ────────────────────────────────────────────────────────

/// Base class for all events emitted by [QueueCoordinator.events].
///
/// Listen to the stream via [FlutterNotificationQueue.events]:
/// ```dart
/// FlutterNotificationQueue.events.listen((event) {
///   switch (event) {
///     case NotificationQueued(:final notification):
///       analytics.track('notification_shown', id: notification.id);
///     case NotificationDismissed(:final notification, :final reason):
///       if (reason == DismissReason.timeout) log('auto-dismissed');
///     case NotificationTapped():
///     case NotificationRelocated():
///     case NotificationReordered():
///     case QueueOverflowed():
///   }
/// });
/// ```
sealed class FnqEvent {
  const FnqEvent();
}

/// Emitted when a [NotificationWidget] is accepted into a queue.
///
/// Not emitted when the notification's channel is disabled.
final class NotificationQueued extends FnqEvent {
  const NotificationQueued({required this.notification});

  /// The notification that was queued.
  final NotificationWidget notification;

  @override
  String toString() =>
      'NotificationQueued(id: ${notification.id}, '
      'queue: ${notification.queue.position.name})';
}

/// Emitted when a [NotificationWidget] is removed from its queue.
final class NotificationDismissed extends FnqEvent {
  const NotificationDismissed({
    required this.notification,
    required this.reason,
  });

  /// The notification that was dismissed.
  final NotificationWidget notification;

  /// Why the notification was dismissed.
  final DismissReason reason;

  @override
  String toString() =>
      'NotificationDismissed(id: ${notification.id}, reason: ${reason.name})';
}

/// Emitted when the user taps a [NotificationWidget].
///
/// Always fired for tap interactions, regardless of the resolved [TapBehavior].
/// Use the [behavior] field to distinguish intent:
/// - [TapToDismiss] — the tap also triggered a [NotificationDismissed] event.
/// - [TapToAct] — the callback has been invoked.
/// - [TapToExpand] — the card toggled its expanded state.
/// - [TapDisabled] — this event is *not* emitted when tapping is disabled.
final class NotificationTapped extends FnqEvent {
  const NotificationTapped({
    required this.notification,
    required this.behavior,
  });

  /// The notification that was tapped.
  final NotificationWidget notification;

  /// The resolved tap behavior that handled this tap.
  final TapBehavior behavior;

  @override
  String toString() =>
      'NotificationTapped(id: ${notification.id}, '
      'behavior: ${behavior.runtimeType})';
}

/// Emitted when a [NotificationWidget] is successfully relocated to a new queue.
final class NotificationRelocated extends FnqEvent {
  const NotificationRelocated({
    required this.notification,
    required this.from,
    required this.to,
  });

  /// The notification after relocation (its [NotificationWidget.queue] now
  /// points to [to]).
  final NotificationWidget notification;

  /// The queue position the notification was moved *from*.
  final QueuePosition from;

  /// The queue position the notification was moved *to*.
  final QueuePosition to;

  @override
  String toString() =>
      'NotificationRelocated(id: ${notification.id}, '
      'from: ${from.name}, to: ${to.name})';
}

/// Emitted when a [NotificationWidget] is reordered within its queue.
final class NotificationReordered extends FnqEvent {
  const NotificationReordered({
    required this.notification,
    required this.toIndex,
  });

  /// The notification that was reordered.
  final NotificationWidget notification;

  /// The new zero-based index within the queue stack.
  final int toIndex;

  @override
  String toString() =>
      'NotificationReordered(id: ${notification.id}, toIndex: $toIndex)';
}

/// Emitted when a notification is dropped because the queue has reached
/// [NotificationQueue.maxStackSize].
final class QueueOverflowed extends FnqEvent {
  const QueueOverflowed({
    required this.queue,
    required this.dropped,
  });

  /// The queue that overflowed.
  final NotificationQueue queue;

  /// The notification that was dropped.
  final NotificationWidget dropped;

  @override
  String toString() =>
      'QueueOverflowed(position: ${queue.position.name}, '
      'dropped: ${dropped.id})';
}
