part of 'enums.dart';

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

  final int thresholdInPixels;
}

final class Relocate<T> extends QueueNotificationBehavior<T> {
  const Relocate._({
    required this.positions,
    super.thresholdInPixels = kDefaultQueueDragBehaviorThreshold,
  });

  factory Relocate.to(final Set<QueuePosition> positions) {
    assert(positions.isNotEmpty, 'positions cannot be empty');
    return Relocate._(positions: positions);
  }

  final Set<QueuePosition> positions;
}

final class Dismiss<T> extends QueueNotificationBehavior<T> {
  const Dismiss({super.thresholdInPixels = kDefaultQueueDragBehaviorThreshold});
}

final class Disabled<T> extends QueueNotificationBehavior<T> {
  const Disabled()
      : super(thresholdInPixels: kDefaultQueueDragBehaviorThreshold);
}

typedef LongPressDragBehavior = QueueNotificationBehavior<OnLongPress>;
typedef DragBehavior = QueueNotificationBehavior<OnDrag>;
