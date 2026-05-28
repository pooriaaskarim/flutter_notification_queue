part of 'core.dart';

/// The configuration registry for [FlutterNotificationQueue].
///
/// Stores [NotificationQueue]s and [NotificationChannel]s.
///
/// This class is internal — users configure the system through
/// [FlutterNotificationQueue.configure] and never interact with this
/// class directly.
@internal
class ConfigurationManager {
  ConfigurationManager({
    final Set<NotificationQueue> queues = const {},
    this.channels = const {},
  }) : queues = _initQueues(queues);

  static Set<NotificationQueue> _initQueues(
    final Set<NotificationQueue> inputQueues,
  ) {
    _validateRelocationGroups(inputQueues);
    _validateInputResilience(inputQueues);
    return _expandRelocationGroups(inputQueues);
  }

  final Set<NotificationQueue> queues;
  final Set<NotificationChannel> channels;

  /// Returns a concise summary of the configuration.
  String get summary => '${queues.length} Queues '
      '(${queues.map((final q) => q.position.name).join(', ')}), '
      '${channels.length} Channels '
      '(${channels.map((final c) => c.name).join(', ')})';

  /// Expands relocation groups: for every [Relocate] behavior,
  /// ensures sibling queues exist and the source position is included
  /// in the target set (self-inclusion, so notifications can return home).
  static Set<NotificationQueue> _expandRelocationGroups(
    final Set<NotificationQueue> inputQueues,
  ) {
    if (inputQueues.isEmpty) {
      return inputQueues;
    }

    final expanded = LinkedHashSet<NotificationQueue>(
      equals: (final a, final b) => a.position == b.position,
      hashCode: (final q) => q.position.hashCode,
    )..addAll(inputQueues);

    for (final queue in inputQueues) {
      for (final behavior in [
        queue.longPressDragBehavior,
        queue.dragBehavior,
      ]) {
        if (behavior is Relocate) {
          final relocate = behavior as Relocate;
          // Self-inclusion: add source position to targets
          relocate.positions.add(queue.position);
          // Expand: create sibling queues for all target positions
          for (final targetPosition in relocate.positions) {
            final alreadyRegistered =
                expanded.any((final q) => q.position == targetPosition);
            if (!alreadyRegistered) {
              expanded.add(targetPosition.generateQueueFrom(queue));
            }
          }
        }
      }
    }
    return expanded;
  }

  /// Validates that no [QueuePosition] appears in multiple relocation groups.
  static void _validateRelocationGroups(
    final Set<NotificationQueue> queues,
  ) {
    final seen = <QueuePosition, NotificationQueue>{};

    for (final queue in queues) {
      final group = <QueuePosition>{};
      var hasRelocate = false;
      for (final behavior in [
        queue.longPressDragBehavior,
        queue.dragBehavior,
      ]) {
        if (behavior is Relocate) {
          hasRelocate = true;
          group.addAll((behavior as Relocate).positions);
        }
      }
      if (!hasRelocate) {
        continue;
      }
      // Include self in group for validation
      group.add(queue.position);

      for (final position in group) {
        if (seen.containsKey(position) && seen[position] != queue) {
          throw ArgumentError(
            '$position appears in both $queue and ${seen[position]} groups. '
            'Relocation is only allowed within the same group.',
          );
        }
        seen[position] = queue;
      }
    }
  }

  /// Validates that queues have at least one interactive way to be dismissed.
  ///
  /// Prevents "Zombie" notifications that cannot be closed by the user.
  static void _validateInputResilience(
    final Set<NotificationQueue> queues,
  ) {
    for (final queue in queues) {
      final isDismissible = queue.dragBehavior is Dismiss ||
          queue.longPressDragBehavior is Dismiss;
      final hasCloseButton = queue.closeButtonBehavior is! Hidden;

      if (!isDismissible && !hasCloseButton) {
        throw ArgumentError(
          'Queue ${queue.position} configuration creates "Zombie"'
          ' notifications. Notifications in this queue cannot be dismissed '
          'by the user because gestures are disabled AND the close button '
          'is hidden.  Please enable at least one interaction method or '
          'show the close button.',
        );
      }
    }
  }

  static final _logger = Logger.get('fnq.Core.Manager');

  /// Resolves a [NotificationChannel] by [channelName].
  ///
  /// Returns the first registered channel if [channelName] is not found,
  /// or a default channel if no channels are registered.
  NotificationChannel getChannel(final String channelName) {
    if (channels.isEmpty) {
      return NotificationChannel.defaultChannel();
    }

    bool registeredChannel = false;
    final notificationChannel = channels.firstWhere(
      (final channel) {
        registeredChannel = channel.name == channelName;
        return registeredChannel;
      },
      orElse: () => NotificationChannel.defaultChannel(),
    );

    if (!registeredChannel) {
      _logger.debug(
        'Channel "$channelName" not found. Falling back to default.',
      );
    }

    return notificationChannel;
  }

  /// Resolves a [NotificationQueue] by [position].
  ///
  /// If [position] is `null`, returns the first registered queue.
  /// If no queue is configured for the given position, generates a new
  /// queue from the default queue's style at the requested position.
  NotificationQueue getQueue(final QueuePosition? position) {
    // 1. Handle Null Position
    if (position == null) {
      if (queues.isNotEmpty) {
        return queues.first;
      }
      return const TopCenterQueue(style: FilledQueueStyle());
    }

    // 2. Find Configured Queue
    final queue = queues.firstWhere(
      (final q) => q.position == position,
      orElse: () => NotificationQueue.defaultQueue(position: position),
    );

    final isGenerated = !queues.contains(queue);

    if (!isGenerated) {
      return queue;
    } else {
      _logger.debug(
        'Position $position not configured. '
        'Generated default queue from style.',
      );
      return position.generateQueueFrom(queue);
    }
  }
}
