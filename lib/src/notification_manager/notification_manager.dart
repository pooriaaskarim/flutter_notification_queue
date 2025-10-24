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

  // static void initialize({
  //   final QueuePosition position = QueuePosition.topCenter,
  //   final EdgeInsets margin =
  //       const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0),
  //   final double spacing = 8.0,
  //   final int maxStackSize = 3,
  //   final int? dismissThreshold = 50,
  //   final QueueIndicatorBuilder? queueIndicatorBuilder,
  //   final QueueStyle queueStyle = const FlatQueueStyle(),
  //   final bool vibrate = false,
  //   final Color? foregroundColor,
  //   final Color? backgroundColor,
  //   final Duration? dismissDuration,
  //   final LongPressDragBehaviour longPressDragBehaviour =
  //       const DisabledLongPressDragBehaviour(),
  //   final DragBehaviour dragBehaviour = const DismissDragBehaviour(),
  //   final QueueCloseButtonBehaviour closeButtonBehaviour =
  //       QueueCloseButtonBehaviour.always,
  //   final Set<NotificationChannel>? channels,
  //   final Set<NotificationQueue>? queues,
  // }) {
  //   assert(NotificationManager._initialized != true, 'Already initialized.');
  //   assert(
  //     maxStackSize > 0,
  //     'maxStackSize must be greater than 0',
  //   );
  //   final defaultChannel = NotificationChannel(
  //     name: 'default',
  //     enabled: true,
  //     position: position,
  //     vibrate: vibrate,
  //     defaultColor: foregroundColor,
  //     defaultBackgroundColor: backgroundColor,
  //     defaultDismissDuration: dismissDuration,
  //   );
  //
  //   _channels.addAll({defaultChannel, ...?channels});
  //   final defaultQueue = position.generateQueue(
  //     closeButtonBehaviour: closeButtonBehaviour,
  //     margin: margin,
  //     maxStackSize: maxStackSize,
  //     queueIndicatorBuilder: queueIndicatorBuilder,
  //     dragBehaviour: dragBehaviour,
  //     longPressDragBehaviour: longPressDragBehaviour,
  //     spacing: spacing,
  //     style: queueStyle,
  //   );
  //   _queues.addAll({defaultQueue, ...?queues});
  //   NotificationManager._initialized = true;
  // }
  static void initialize({
    final Set<NotificationChannel>? channels,
    final Set<NotificationQueue>? queues,
  }) {
    assert(NotificationManager._initialized != true, 'Already initialized.');
    NotificationManager._initialized = true;
    if (queues?.any(
          (final queue) => queue.position == QueuePosition.topCenter,
        ) ??
        false) {
      _queues.clear();
    }
    _queues.addAll(queues ?? {});
    if (channels?.any(
          (final channel) => channel.name == 'default',
        ) ??
        false) {
      _channels.clear();
    }
    _channels.addAll(channels ?? {});
  }

  static final LinkedHashSet<NotificationChannel> _channels = LinkedHashSet(
    equals: (
      final x,
      final y,
    ) =>
        x.name == y.name,
  )..add(
      const NotificationChannel(
        name: 'default',
        position: QueuePosition.topCenter,
        description: 'Default notification channel.',
      ),
    );
  static final LinkedHashSet<NotificationQueue> _queues = LinkedHashSet(
    equals: (
      final x,
      final y,
    ) =>
        x.position == y.position,
  )..add(
      TopCenterQueue(
        style: const FlatQueueStyle(),
      ),
    );

  static bool isEmptyPosition(final QueuePosition position) =>
      _queues.where((final queue) => queue.position == position).isEmpty;

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

    debugPrint('''
---NotificationManager:::getChannel---
----|Channel: $channelName
----|Channels: $_channels
----|${registeredChannel ? 'Registered Channel' : 'Unregistered Channel. Defaulting to NotificationManager default channel'}. 
----|NotificationChannel: $notificationChannel
''');
    return notificationChannel;
  }

  NotificationQueue getQueue(
    final QueuePosition? position,
  ) {
    debugPrint('''
--NotificationManager:::getQueue--
----|Position: $position
----|Queues: $_queues''');
    if (position == null) {
      final defaultQueue = _queues.first;
      debugPrint('''
----|No Position provided,
----|Returning default queue: $defaultQueue
''');

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

    debugPrint('''
----|${configuredQueue ? 'Configured Queue.' : 'Unconfigured Queue. Defaulting to default queue at new position.'} 
----|Queue: $queue
''');
    return queue;
  }

  void show(
    final NotificationWidget notification,
    final BuildContext context,
  ) {
    debugPrint('''
--NotificationManager:::show--
----|Notification: $notification
----|Context: $context
''');
    notification.queue.manager.queue(notification, context);
  }

  ///Relocate [NotificationWidget] to a new [QueuePosition]
  void relocate(
    final NotificationWidget notification,
    final QueuePosition newPosition,
    final BuildContext context,
  ) {
    debugPrint('''
--NotificationManager:::relocate--
----|Notification: $notification
----|Context: $context
----|CurrentPosition: ${notification.position}
----|NewPosition: $newPosition
----|-----> ${notification.queue.position == newPosition ? 'Same Position, Skipping relocation.' : 'Relocating... .'}
''');
    final relocatingNotification = notification.copyWith(newPosition);
    final oldQueue = notification.queue;
    final newQueue = relocatingNotification.queue;
    if (newQueue == oldQueue) {
      return;
    }
    // notification
    //   ..position = newPosition
    //   ..queue = newQueue;
    oldQueue.manager.dismiss(notification, context);
    newQueue.manager.queue(relocatingNotification, context);
  }

  /// Dismiss [NotificationWidget] from it's [NotificationQueue]
  void dismiss(
    final NotificationWidget notification,
    final BuildContext context,
  ) {
    debugPrint('''
--NotificationManager:::dismiss--
----|Notification: $notification
----|Context: $context
''');
    notification.queue.manager.dismiss(notification, context);
  }
}
