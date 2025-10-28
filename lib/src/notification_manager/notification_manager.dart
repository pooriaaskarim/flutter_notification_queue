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
    final Set<NotificationChannel>? channels,
    final Set<NotificationQueue>? queues,
  }) {
    assert(NotificationManager._initialized != true, 'Already initialized.');
    NotificationManager._initialized = true;
    if (queues != null && queues.isNotEmpty) {
      for (final queue in queues) {
        final otherQueues = {...queues}..remove(queue);
        for (final target in queue.groupPosition) {
          for (final anotherQueue in otherQueues) {
            if (anotherQueue.groupPosition.contains(target)) {
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
          ...queue.groupPosition.map(
            (final p) => p.generateQueueFrom(queue),
          ),
        },
      };
      _queues.addAll(resolvedQueue);
    } else {
      _queues.add(
        TopCenterQueue(
          style: const FilledQueueStyle(),
        ),
      );
    }

    if (channels != null && channels.isNotEmpty) {
      _channels.addAll(channels);
    } else {
      _channels.add(
        const NotificationChannel(
          name: 'default',
          position: QueuePosition.topCenter,
          description: 'Default notification channel.',
        ),
      );
    }
  }

  static final _channels = LinkedHashSet<NotificationChannel>(
    equals: (
      final x,
      final y,
    ) =>
        x.name == y.name,
  );
  static final _queues = LinkedHashSet<NotificationQueue>(
    equals: (
      final x,
      final y,
    ) =>
        x.position == y.position,
  );

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
