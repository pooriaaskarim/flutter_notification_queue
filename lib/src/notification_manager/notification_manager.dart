import 'dart:collection';

import 'package:flutter/material.dart';

import '../../flutter_notification_queue.dart';

class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  /// Default [NotificationChannel]
  ///
  /// Any [NotificationWidget] with and unregistered
  /// [NotificationWidget.channelName] will default to this channel.
  NotificationChannel _defaultChannel = const NotificationChannel(
    name: 'default',
  );

  /// Configures the default [NotificationChannel]
  /// and default [NotificationQueue] of the [NotificationManager].
  void initialize({
    final QueuePosition position = QueuePosition.topCenter,
    final EdgeInsets? margin =
        const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
    final double spacing = 8.0,
    final int maxStackSize = 3,
    final double dismissalThreshold = 50.0,
    final PendingIndicatorBuilder? queueIndicatorBuilder,
    final double opacity = 0.8,
    final double elevation = 3.0,
    final bool showCloseButton = true,
    final bool vibrate = false,
    final Color? defaultForegroundColor,
    final Color? defaultBackgroundColor,
    final Duration? defaultDismissDuration,
  }) {
    assert(
      maxStackSize > 0,
      'maxStackSize must be greater than 0',
    );
    _defaultChannel = NotificationChannel(
      name: 'default',
      enabled: true,
      position: position,
      vibrate: vibrate,
      defaultForegroundColor: defaultForegroundColor,
      defaultBackgroundColor: defaultBackgroundColor,
      defaultDismissDuration: defaultDismissDuration,
    );
    _defaultQueue = position.queue(
      margin: margin,
      spacing: spacing,
      maxStackSize: maxStackSize,
      dismissalThreshold: dismissalThreshold,
      queueIndicatorBuilder: queueIndicatorBuilder,
      opacity: opacity,
      elevation: elevation,
      showCloseButton: showCloseButton,
    );
  }

  final Set<NotificationChannel> _channels = HashSet();
  Set<NotificationChannel> get channels => {..._channels, _defaultChannel};

  /// Configures [NotificationChannel]s
  void registerChannels({
    final Set<NotificationChannel>? channels,
  }) {
    _channels.addAll({...?channels});
  }

  /// Default [NotificationQueue]
  ///
  /// Any unconfigured [QueuePosition] will default to this queue.
  NotificationChannel getChannel(
    final String channelName,
  ) {
    bool registered = false;
    final notificationChannel = channels.firstWhere(
      (final channel) {
        final found = channel.name == channelName;
        if (found) {
          registered = true;
        }
        return found;
      },
      orElse: () => _defaultChannel,
    );

    debugPrint('''
---NotificationManager:::getChannel---
------channel: $channelName
------${registered ? 'Registered Channel.' : 'Unregistered Channel. Defaulting to NotificationManager default channel.'} 
------notificationChannel: $notificationChannel
''');
    return notificationChannel;
  }

  NotificationQueue _defaultQueue = TopCenterQueue();

  /// Configures [NotificationQueue]s for different [QueuePosition]s.
  void configureQueues({
    final Set<NotificationQueue>? queues,
  }) {
    _queues.addAll({...?queues});
  }

  final Set<NotificationQueue> _queues = HashSet();
  Set<NotificationQueue> get queues => {..._queues, _defaultQueue};

  NotificationQueue getQueue(
    final QueuePosition? position,
  ) {
    debugPrint('''
---NotificationManager:::getQueue---
------position: $position''');
    if (position == null) {
      debugPrint('''
------No Position provided,
------Returning default queue: $_defaultQueue
''');
      return _defaultQueue;
    }
    bool configuredQueue = false;
    final NotificationQueue queue = queues.firstWhere(
      (final queue) {
        final found = queue.position == position;
        if (found) {
          configuredQueue = true;
        }
        return found;
      },
      orElse: () => _defaultQueue,
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
    getQueue(notification.position).manager.add(notification, context);
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
    getQueue(notification.position).manager.dismiss(notification, context);
  }
}
