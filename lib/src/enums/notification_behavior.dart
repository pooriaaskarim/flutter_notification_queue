part of 'enums.dart';

/// The default distance (in pixels) from the screen edge required to trigger
/// a drag behavior (relocate or dismiss).
///
/// Defaults to 50 logical pixels.
const int kDefaultQueueDragBehaviorThreshold = 50;

// Phantom markers (internal, not exposed to users)
class OnDrag {}

class OnLongPress {}

sealed class QueueNotificationBehavior<T> {
  const QueueNotificationBehavior({required this.thresholdInPixels})
      : assert(
          thresholdInPixels >= kDefaultQueueDragBehaviorThreshold,
          'thresholdInPixels must be greater than '
          'kDefaultQueueBehaviorThreshold Pixels',
        );

  /// Pixels left from the edge of the screen to trigger the behavior.
  final int thresholdInPixels;
}

/// Relocates the notification to the specified positions.
///
/// Moves the notification to the specified positions when the notification
/// is dragged to the edge of the screen.
final class Relocate<T> extends QueueNotificationBehavior<T> {
  const Relocate._({
    required this.positions,
    super.thresholdInPixels = kDefaultQueueDragBehaviorThreshold,
  });

  factory Relocate.to(final Set<QueuePosition> positions) {
    if (positions.isEmpty) {
      throw ArgumentError.value(
        positions,
        'positions',
        'positions must not be empty',
      );
    }
    return Relocate._(positions: positions);
  }

  final Set<QueuePosition> positions;
}

/// Defines the screen zones where the notification can be dismissed.
enum DismissZone {
  /// The notification can be dismissed by dragging it to the left or right
  /// edges of the screen.
  ///
  /// These zones are vertically centered based on the queue's position.
  /// for example:
  /// * For top queues, the zones are near the top of the screen.
  /// * For center queues, the zones are in the middle of the screen.
  /// * For bottom queues, the zones are near the bottom of the screen.
  sideEdges,

  /// The notification can be dismissed by dragging it in the natural direction
  /// relative to its queue position.
  ///
  /// * For top positions, drag **up** to the top edge.
  /// * For bottom positions, drag **down** to the bottom edge.
  /// * For center positions, the natural direction matches the [sideEdges]
  /// behavior.
  naturalDirection,
}

/// Dismisses the notification.
///
/// Dismisses the notification when the notification is dragged to the edge of
/// the screen.
final class Dismiss<T> extends QueueNotificationBehavior<T> {
  const Dismiss({
    super.thresholdInPixels = kDefaultQueueDragBehaviorThreshold,
    this.zones = DismissZone.sideEdges,
  });

  /// The zones where the notification can be dismissed.
  ///
  /// Defaults to [DismissZone.sideEdges].
  final DismissZone zones;
}

/// Reorders the notification within its current queue.
///
/// When the user drags the notification, slot targets appear between all
/// notifications in the stack. Dropping onto a slot moves this notification
/// to that index.
final class Reorder<T> extends QueueNotificationBehavior<T> {
  const Reorder({
    super.thresholdInPixels = kDefaultQueueDragBehaviorThreshold,
  });
}

final class Disabled<T> extends QueueNotificationBehavior<T> {
  const Disabled()
      : super(thresholdInPixels: kDefaultQueueDragBehaviorThreshold);
}

typedef LongPressDragBehavior = QueueNotificationBehavior<OnLongPress>;
typedef DragBehavior = QueueNotificationBehavior<OnDrag>;
