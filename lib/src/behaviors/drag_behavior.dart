part of 'behaviors.dart';

/// The default distance (in pixels) from the screen edge required to trigger
/// a drag behavior (relocate or dismiss).
///
/// Defaults to 50 logical pixels.
const int kDefaultQueueDragBehaviorThreshold = 50;

// Phantom markers (internal, not exposed to users)
class OnDrag {}

class OnLongPress {}

sealed class QueueNotificationBehavior<T> {
  const QueueNotificationBehavior({
    required this.thresholdInPixels,
    this.springPhysics = const SpringPhysicsConfiguration.premium(),
  }) : assert(
          thresholdInPixels >= kDefaultQueueDragBehaviorThreshold,
          'thresholdInPixels must be greater than '
          'kDefaultQueueBehaviorThreshold Pixels',
        );

  /// Pixels left from the edge of the screen to trigger the behavior.
  final int thresholdInPixels;

  /// Configuration for physical spring simulations during snap-back.
  final SpringPhysicsConfiguration springPhysics;
}

/// Relocates the notification to the specified positions.
///
/// Moves the notification to the specified positions when the notification
/// is dragged to the edge of the screen.
final class Relocate<T> extends QueueNotificationBehavior<T> {
  const Relocate._({
    required this.positions,
    super.thresholdInPixels = kDefaultQueueDragBehaviorThreshold,
    super.springPhysics = const SpringPhysicsConfiguration.premium(),
  });

  factory Relocate.to(
    final Set<QueuePosition> positions, {
    final SpringPhysicsConfiguration springPhysics =
        const SpringPhysicsConfiguration.premium(),
  }) {
    if (positions.isEmpty) {
      throw ArgumentError.value(
        positions,
        'positions',
        'positions must not be empty',
      );
    }
    return Relocate._(
      positions: positions,
      springPhysics: springPhysics,
    );
  }

  final Set<QueuePosition> positions;
}

/// Dismisses the notification.
///
/// Dismisses the notification when the notification is dragged to the edge of
/// the screen.
final class Dismiss<T> extends QueueNotificationBehavior<T> {
  const Dismiss({
    super.thresholdInPixels = kDefaultQueueDragBehaviorThreshold,
    super.springPhysics = const SpringPhysicsConfiguration.premium(),
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
    super.springPhysics = const SpringPhysicsConfiguration.premium(),
  });
}

final class ReorderAndRelocate<T> extends QueueNotificationBehavior<T> {
  const ReorderAndRelocate._({
    required this.positions,
    super.thresholdInPixels = kDefaultQueueDragBehaviorThreshold,
    super.springPhysics = const SpringPhysicsConfiguration.premium(),
    this.escapeThresholdInPixels = 80.0,
  });

  factory ReorderAndRelocate.to({
    required final Set<QueuePosition> positions,
    final double escapeThresholdInPixels = 80.0,
    final SpringPhysicsConfiguration springPhysics =
        const SpringPhysicsConfiguration.premium(),
  }) {
    if (positions.isEmpty) {
      throw ArgumentError.value(
        positions,
        'positions',
        'positions must not be empty',
      );
    }
    return ReorderAndRelocate._(
      positions: positions,
      escapeThresholdInPixels: escapeThresholdInPixels,
      springPhysics: springPhysics,
    );
  }

  final Set<QueuePosition> positions;

  /// Pixels beyond the source queue's rendered bounding box at which the
  /// system switches from Reorder to Relocate mode.
  final double escapeThresholdInPixels;
}

final class Disabled<T> extends QueueNotificationBehavior<T> {
  const Disabled()
      : super(
          thresholdInPixels: kDefaultQueueDragBehaviorThreshold,
          springPhysics: const SpringPhysicsConfiguration(),
        );
}

typedef LongPressDragBehavior = QueueNotificationBehavior<OnLongPress>;
typedef DragBehavior = QueueNotificationBehavior<OnDrag>;
