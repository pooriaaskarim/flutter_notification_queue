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
      return const NotificationChannel(
        name: 'default',
        position: QueuePosition.topCenter,
        description: 'Default notification channel.',
      );
    }

    bool registeredChannel = false;
    final notificationChannel = channels.firstWhere(
      (final channel) {
        registeredChannel = channel.name == channelName;
        return registeredChannel;
      },
      orElse: () => channels.first,
    );

    _logger.debugBuffer
      ?..writeAll([
        'Channel: $channelName',
        (registeredChannel
            ? 'Registered Channel'
            : 'Unregistered Channel. Defaulting to default channel'),
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
    }

    // 2. Find Configured Queue
    try {
      final queue = queues.firstWhere((final q) => q.position == position);
      b
        ?..writeln('Configured Queue found: $queue')
        ..sink();
      return queue;
    } catch (_) {
      // 3. Generate Fallback
      // We can't mutate `queues` because this class is immutable.
      // We must generate a notification queue config on the fly.
      // This is safe because state is now in QueueCoordinator!

      final NotificationQueue defaultQueue = queues.isNotEmpty
          ? queues.first
          : const TopCenterQueue(style: FilledQueueStyle());

      final generatedQueue = position.generateQueueFrom(defaultQueue);

      b
        ?..writeln('Unconfigured Queue. Generated default at position.')
        ..writeln('Queue: $generatedQueue')
        ..sink();

      return generatedQueue;
    }
  }
}
