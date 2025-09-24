import 'dart:collection';

import 'package:flutter/material.dart';

import '../../flutter_notification_queue.dart';

class NotificationManager {
  NotificationManager._()
      : assert(
          _initialized != null,
          'NotificationManager must be initialized before use.'
          ' Please call NotificationManager.initialize() first.',
        );
  static final NotificationManager instance = NotificationManager._();

  static bool? _initialized;

  static void initialize({
    final QueuePosition position = QueuePosition.topCenter,
    final EdgeInsets? margin =
        const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    final double spacing = 8.0,
    final int maxStackSize = 3,
    final double dismissalThreshold = 50.0,
    final PendingIndicatorBuilder? queueIndicatorBuilder,
    final QueueStyle queueStyle = const FlatQueueStyle(),
    final bool vibrate = false,
    final Color? foregroundColor,
    final Color? backgroundColor,
    final Duration? dismissDuration,
    final Set<NotificationChannel>? channels,
    final Set<NotificationQueue>? queues,
  }) {
    assert(NotificationManager._initialized != true, 'Already initialized.');
    assert(
      maxStackSize > 0,
      'maxStackSize must be greater than 0',
    );
    final defaultChannel = NotificationChannel(
      name: 'default',
      enabled: true,
      position: position,
      vibrate: vibrate,
      defaultForegroundColor: foregroundColor,
      defaultBackgroundColor: backgroundColor,
      defaultDismissDuration: dismissDuration,
    );

    _channels.addAll({defaultChannel, ...?channels});
    final defaultQueue = position.generateQueue(
      style: queueStyle,
      spacing: spacing,
      maxStackSize: maxStackSize,
      dismissalThreshold: dismissalThreshold,
      queueIndicatorBuilder: queueIndicatorBuilder,
    );
    _queues.addAll({defaultQueue, ...?queues});
    NotificationManager._initialized = true;
  }

  static final LinkedHashSet<NotificationChannel> _channels = LinkedHashSet();
  static final LinkedHashSet<NotificationQueue> _queues = LinkedHashSet();

  NotificationChannel _getChannel(
    final String channelName,
  ) {
    bool registered = false;
    final notificationChannel = _channels.firstWhere(
      (final channel) {
        final found = channel.name == channelName;
        if (found) {
          registered = true;
        }
        return found;
      },
      orElse: () => _channels.first,
    );

    debugPrint('''
---NotificationManager:::getChannel---
------channel: $channelName
------channels: $_channels
------${registered ? 'Registered Channel.' : 'Unregistered Channel. Defaulting to NotificationManager default channel.'} 
------notificationChannel: $notificationChannel
''');
    return notificationChannel;
  }

  NotificationQueue _getQueue(
    final QueuePosition? position,
  ) {
    debugPrint('''
---NotificationManager:::getQueue---
------position: $position
------queues: $_queues''');
    if (position == null) {
      final defaultQueue = _queues.first;
      debugPrint('''
------No Position provided,
------Returning default queue: $defaultQueue
''');

      return defaultQueue;
    }
    bool configuredQueue = false;
    final NotificationQueue queue = _queues.firstWhere(
      (final queue) {
        final found = queue.position == position;
        if (found) {
          configuredQueue = true;
        }
        return found;
      },
      orElse: () {
        final defaultQueue = _queues.first;

        final generateQueueFromDefault =
            position.generateQueueFrom(defaultQueue);
        _queues.add(generateQueueFromDefault);
        return generateQueueFromDefault;
      },
    );

    debugPrint('''
------${configuredQueue ? 'Configured Queue.' : 'Unconfigured Queue. Defaulting to NotificationManager default queue.'} 
------queue: $queue
''');
    return queue;
  }

  void show(
    final NotificationWidget notification,
    final BuildContext context,
  ) {
    debugPrint('''
---NotificationManager:::show---
------notification: $notification
------context: $context
''');
    notification
      ..channel = _getChannel(notification.channelName)
      ..queue =
          _getQueue(notification.position ?? notification.channel.position)
      ..queue.manager.queue(notification, context);
  }

  /// Dismiss [NotificationWidget] from it's [NotificationQueue]
  void dismiss(
    final NotificationWidget notification,
    final BuildContext context,
  ) {
    debugPrint('''
---NotificationManager:::dismiss---
------notification: $notification
------context: $context
''');
    notification.queue.manager.dismiss(notification, context);
  }
}
