part of 'core.dart';

/// The configuration registry for the notification system.
///
/// Stores [NotificationQueue]s and [NotificationChannel]s, and resolves
/// lookups by name (channels) or [QueuePosition] (queues). Acts as the
/// single source of truth for system configuration.
///
/// This class is internal — users configure the system through
/// [FlutterNotificationQueue.initialize] and never interact with this
/// class directly.
///
/// ## Lifecycle
///
/// 1. [configure] is called by [FlutterNotificationQueue.initialize].
/// 2. If no queues/channels are provided, sensible defaults are applied
///    (a [TopCenterQueue] with [FilledQueueStyle] and a `"default"` channel).
/// 3. The [instance] singleton is then available for resolution via
///    [getChannel] and [getQueue]. Accessing [instance] before initialization
///    will throw a [StateError].
///
/// ## Resolution Strategy
///
/// - **Channels**: Resolved by name. If a requested channel name is not
///   registered, falls back to the first registered channel.
/// - **Queues**: Resolved by [QueuePosition]. If a requested position has
///   no configured queue, a new queue is generated from the default queue's
///   style at the requested position.
class ConfigurationManager {
  ConfigurationManager._() {
    if (!_initialized) {
      throw StateError(
        'ConfigurationManager is not initialized. '
        'Call FlutterNotificationQueue.initialize() first.',
      );
    }
  }

  static final ConfigurationManager instance = ConfigurationManager._();
  static bool _initialized = false;
  static final _logger = Logger.get('fnq.Core.Manager');

  /// Whether the configuration system has been initialized.
  static bool get isInitialized => _initialized;

  /// Registers queues and channels into the system.
  ///
  /// Called by [FlutterNotificationQueue.initialize].
  ///
  /// Validates that no two queues share the same [QueuePosition] in their
  /// relocation groups. Skips default-insertion if queues or channels are
  /// already populated (prevents overwrites on repeated calls).
  static void configure({
    final Set<NotificationQueue>? queues,
    final Set<NotificationChannel>? channels,
  }) {
    final b = _logger.debugBuffer;
    if (!_initialized) {
      b?.writeAll(['Initializing... .']);
      _initialized = true;
    }
    if (queues != null && queues.isNotEmpty) {
      b?.writeAll(['Configuring queues: $queues']);

      for (final queue in queues) {
        final otherQueues = {...queues}..remove(queue);
        for (final target in queue.groupPositions) {
          for (final anotherQueue in otherQueues) {
            if (anotherQueue.groupPositions.contains(target)) {
              throw ArgumentError(
                  '$target is used in both $queue and inside $anotherQueue,'
                  '\nRelocation is allowed only in the same Group.');
            }
          }
        }
      }
      final resolvedQueue = <NotificationQueue>{
        for (final queue in queues) ...{
          queue,
          ...queue.groupPositions.map(
            (final p) => p.generateQueueFrom(queue),
          ),
        },
      };
      _queues.addAll(resolvedQueue);
    } else if (_queues.isEmpty) {
      _queues.add(
        TopCenterQueue(
          style: const FilledQueueStyle(),
        ),
      );
      b?.writeAll([
        'No queues provided, adding default queue.',
        'Queues: $_queues',
      ]);
    }
    if (channels != null && channels.isNotEmpty) {
      b?.writeAll(['Configuring channels: $channels']);

      _channels.addAll(channels);
    } else if (_channels.isEmpty) {
      _channels.add(
        const NotificationChannel(
          name: 'default',
          position: QueuePosition.topCenter,
          description: 'Default notification channel.',
        ),
      );
      b?.writeAll([
        'No channels provided, adding default channel.',
        'Default channel added.',
        'Channels: $_channels',
      ]);
    }
    b?.sink();
  }

  static final _channels = LinkedHashSet<NotificationChannel>(
    equals: (
      final x,
      final y,
    ) =>
        x.name == y.name,
    hashCode: (final c) => c.name.hashCode,
  );
  static final _queues = LinkedHashSet<NotificationQueue>(
    equals: (
      final x,
      final y,
    ) =>
        x.position == y.position,
    hashCode: (final q) => q.position.hashCode,
  );

  /// Resolves a [NotificationChannel] by [channelName].
  ///
  /// Returns the first registered channel if [channelName] is not found.
  NotificationChannel getChannel(
    final String channelName,
  ) {
    bool registeredChannel = false;
    final notificationChannel = _channels.firstWhere(
      (final channel) {
        registeredChannel = channel.name == channelName;
        return registeredChannel;
      },
      orElse: () => _channels.first,
    );
    _logger.debugBuffer
      ?..writeAll([
        'Channel: $channelName',
        'Channels: $_channels',
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
  NotificationQueue getQueue(
    final QueuePosition? position,
  ) {
    final b = _logger.debugBuffer
      ?..writeAll([
        'Position: $position',
        'Queues: $_queues',
      ]);

    if (position == null) {
      final defaultQueue = _queues.first;
      b
        ?..writeAll([
          'No Position provided,',
          'Returning default queue: $defaultQueue',
        ])
        ..sink();
      return defaultQueue;
    }
    bool configuredQueue = false;
    final NotificationQueue queue = _queues.firstWhere(
      (final queue) {
        configuredQueue = queue.position == position;
        return configuredQueue;
      },
      orElse: () {
        final defaultQueue = _queues.first;
        final generateQueueFromDefault =
            position.generateQueueFrom(defaultQueue);
        _queues.add(generateQueueFromDefault);
        return generateQueueFromDefault;
      },
    );
    b
      ?..writeAll([
        (
          configuredQueue
              ? 'Configured Queue.'
              : 'Unconfigured Queue. Defaulting to default queue at '
                  'new position.',
        ),
        'Queue: $queue',
      ])
      ..sink();

    return queue;
  }
}
