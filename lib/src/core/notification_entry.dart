part of 'core.dart';

/// Internal representation of a queued/active notification.
///
/// Holds the active lifecycle state, timers, and animations, separating
/// configuration blueprints ([NotificationWidget]) from run-time state.
@internal
class NotificationEntry {
  NotificationEntry({
    required this.blueprint,
    required this.queue,
  })  : id = blueprint.id,
        createdAt = blueprint.createdAt,
        snoozedAt = blueprint.snoozedAt,
        groupKey = blueprint.groupKey,
        isPinnedNotifier = ValueNotifier<bool>(blueprint.isPinned);

  /// The original [NotificationWidget] configuration blueprint.
  final NotificationWidget blueprint;

  /// The unique identifier of this notification entry.
  final String id;

  /// The target queue position this entry is currently routed to.
  NotificationQueue queue;

  /// The name of the channel.
  String get channelName => blueprint.channelName;

  /// The resolved channel configuration.
  NotificationChannel get channel => blueprint.channel;

  /// The title of the notification.
  String? get title => blueprint.title;

  /// The message body.
  String get message => blueprint.message;

  /// The resolved priority level of the notification.
  NotificationPriority get resolvedPriority => blueprint.resolvedPriority;

  /// ValueNotifier tracking the pinned status of this entry.
  final ValueNotifier<bool> isPinnedNotifier;

  /// Whether this entry is currently pinned.
  bool get isPinned => isPinnedNotifier.value;
  set isPinned(final bool value) {
    isPinnedNotifier.value = value;
    blueprint.isPinned = value;
  }

  /// The timestamp when this notification was created.
  final DateTime createdAt;

  /// The timestamp when this notification was snoozed, if any.
  final DateTime? snoozedAt;

  /// Optional group key for bundling.
  final String? groupKey;

  /// The resolved group key, falling back to channel name.
  String get resolvedGroupKey => groupKey ?? channelName;

  /// Helper to create a new copy relocated to a target queue.
  NotificationEntry copyToQueue(final NotificationQueue targetQueue) {
    final newBlueprint = blueprint.copyToQueue(targetQueue);
    return NotificationEntry(
      blueprint: newBlueprint,
      queue: targetQueue,
    );
  }

  /// Helper to create a new copy for re-queuing (e.g. after snooze).
  NotificationEntry copyForRequeue({final DateTime? snoozedAt}) {
    final newBlueprint = blueprint.copyForRequeue(snoozedAt: snoozedAt);
    return NotificationEntry(
      blueprint: newBlueprint,
      queue: queue,
    );
  }
}
