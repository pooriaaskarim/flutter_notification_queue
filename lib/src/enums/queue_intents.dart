part of 'enums.dart';

/// Triggers a snooze action, temporarily dismissing the notification and
/// re-displaying it after the specified duration.
final class Snooze<T> extends QueueNotificationBehavior<T> {
  const Snooze({
    required this.duration,
    super.thresholdInPixels = kDefaultQueueDragBehaviorThreshold,
    super.springPhysics = const SpringPhysicsConfiguration.premium(),
  });

  /// The duration to snooze the notification.
  final Duration duration;
}

/// Pins the notification, preventing gesture-based dismissals and styling it
/// dynamically to indicate its persistent/pinned status.
final class Pin<T> extends QueueNotificationBehavior<T> {
  const Pin({
    super.thresholdInPixels = kDefaultQueueDragBehaviorThreshold,
    super.springPhysics = const SpringPhysicsConfiguration.premium(),
  });
}

/// Archives the notification, removing it from the queue and triggering
/// a semantic archive callback.
final class Archive<T> extends QueueNotificationBehavior<T> {
  const Archive({
    super.thresholdInPixels = kDefaultQueueDragBehaviorThreshold,
    super.springPhysics = const SpringPhysicsConfiguration.premium(),
  });
}

/// Triggers a developer-defined custom action identified by a unique action
/// label.
final class CustomAction<T> extends QueueNotificationBehavior<T> {
  const CustomAction({
    required this.actionName,
    super.thresholdInPixels = kDefaultQueueDragBehaviorThreshold,
    super.springPhysics = const SpringPhysicsConfiguration.premium(),
  });

  /// The unique key representing this custom action.
  final String actionName;
}
