part of 'core.dart';

/// The configuration registry for [FlutterNotificationQueue].
///
/// Stores [NotificationQueue]s and [NotificationChannel]s.
///
/// This class is internal — users configure the system through
/// [FlutterNotificationQueue.initialize] and never interact with this
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
    return _expandRelocationGroups(inputQueues);
  }

  final Set<NotificationQueue> queues;
  final Set<NotificationChannel> channels;

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

    _logger.debugBuffer
      ?..writeAll([
        'Channel: $channelName',
        (registeredChannel
            ? 'Registered Channel'
            : 'Unregistered Channel. Defaulting to the default channel!'),
        'NotificationChannel: $notificationChannel',
      ])
      ..sink();

    return notificationChannel;
  }

  /// Resolves a [NotificationQueue] by [position].
  ///
  /// If [position] is `null`, returns the first registered queue.
  /// If no queue is configured for the given position, generates a new
  /// queue from the default queue's style at the requested position.
  NotificationQueue getQueue(final QueuePosition? position) {
    final b = _logger.debugBuffer?..write('Position: $position');

    // 1. Handle Null Position
    if (position == null) {
      final NotificationQueue defaultQueue;
      if (queues.isNotEmpty) {
        defaultQueue = queues.first;
      } else {
        defaultQueue = const TopCenterQueue(style: FilledQueueStyle());
      }

      b
        ?..writeAll([
          'No Position provided,',
          'Returning default queue: $defaultQueue',
        ])
        ..sink();
      return defaultQueue;
    } else {
      // 2. Find Configured Queue
      try {
        final queue = queues.firstWhere((final q) => q.position == position);
        b
          ?..writeln('Configured Queue found: $queue')
          ..sink();
        return queue;
      } catch (_) {
        final generatedQueue = position.generateQueueFrom(
          NotificationQueue.defaultQueue(position: position),
        );

        b
          ?..writeln('Unconfigured Queue. Generated default at position.')
          ..writeln('Queue: $generatedQueue')
          ..sink();

        return generatedQueue;
      }
    }
  }
}
