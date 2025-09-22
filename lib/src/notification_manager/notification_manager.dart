import 'dart:collection';

import 'package:flutter/material.dart';

import '../../flutter_notification_queue.dart';
import '../notification_queue/queue_manager.dart';

class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  void configureDefaultChannel({
    final AlignmentDirectional defaultAlignment =
        AlignmentDirectional.topCenter,
    final bool vibrate = false,
    final Color? defaultForegroundColor,
    final Color? defaultBackgroundColor,
    final Duration? defaultDismissDuration,
  }) =>
      _defaultChannel = NotificationChannel(
        name: 'default',
        enabled: true,
        alignment: defaultAlignment,
        vibrate: vibrate,
        defaultForegroundColor: defaultForegroundColor,
        defaultBackgroundColor: defaultBackgroundColor,
        defaultDismissDuration: defaultDismissDuration,
      );
  NotificationChannel _defaultChannel = const NotificationChannel(
    name: 'default',
  );

  void configureDefaultQueue(
    final NotificationQueue queue,
  ) {
    _defaultQueue = queue;
    _defaultChannel = _defaultChannel.copyWith(alignment: queue.alignment);
  }

  NotificationQueue _defaultQueue = const TopCenterQueue();

  final Set<NotificationChannel> _channels = HashSet();

  /// Configures [NotificationChannel]s
  void registerChannels({
    final Set<NotificationChannel>? channels,
  }) {
    _channels.addAll({...?channels});
  }

  /// Configures [QueueManager]s based on
  /// their ***position on the screen***.
  ///
  /// Provide a set of [QueueManager] and configure them with
  /// [NotificationQueue].
  void configureQueues({
    final Set<NotificationQueue>? queues,
  }) {
    _queues.addAll({...?queues});
  }

  final Set<NotificationQueue> _queues = HashSet();
  final Map<AlignmentDirectional, QueueManager> _queueManagers = HashMap();

  NotificationChannel getNotificationChannel(
    final NotificationWidget notification,
  ) =>
      _channels.firstWhere(
        (final channel) => channel.name == notification.notificationChannel,
        orElse: () => _defaultChannel,
      );

  NotificationQueue getQueue(
    final NotificationWidget notification,
  ) =>
      _queues.firstWhere(
        (final queue) =>
            queue.alignment == notification.configuration.alignment,
        orElse: () => _defaultQueue,
      );

  /// Shows a [NotificationWidget] on it's resolve [NotificationQueue].
  void show(
    final NotificationWidget notification,
    final BuildContext context,
  ) {}

  /// Dismiss [NotificationWidget] from it's [NotificationQueue]
  bool dismiss(
    final NotificationWidget notification,
  ) =>
      throw UnimplementedError();
}
