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
  const ConfigurationManager({
    this.queues = const {},
    this.channels = const {},
  });

  final Set<NotificationQueue> queues;
  final Set<NotificationChannel> channels;

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
