import 'dart:collection';

import 'package:flutter/material.dart';

import '../../../flutter_notification_queue.dart';

class NotificationManager {
  NotificationManager._()
      : assert(
          initialized,
          'NotificationQueue:'
          '\n NotificationManager must be initialized before use.'
          '\n Please wrap your root widget inside a'
          ' NotificationQueueWrapper first.',
        );
  static final NotificationManager instance = NotificationManager._();
  static bool initialized = false;

  static void configure({
    final Set<NotificationQueue>? queues,
    final Set<NotificationChannel>? channels,
  }) {
    // assert(NotificationManager._initialized != true, 'Already initialized.');
    debugPrint('''
--NotificationManager:::configure--''');
    if (!initialized) {
      debugPrint('''
----|Initializing...''');
      NotificationManager.initialized = true;
    }
    if (queues != null && queues.isNotEmpty) {
      debugPrint('''
----|Configuring queues: $queues''');
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
    } else {
      _queues.add(
        TopCenterQueue(
          style: const FilledQueueStyle(),
        ),
      );
      debugPrint('''
----|No queues provided, adding default queue.
----|Default queue added.
----|Queues: $_queues''');
    }
    if (channels != null && channels.isNotEmpty) {
      debugPrint('''
----|Configuring channels: $channels
''');
      _channels.addAll(channels);
    } else {
      _channels.add(
        const NotificationChannel(
          name: 'default',
          position: QueuePosition.topCenter,
          description: 'Default notification channel.',
        ),
      );
      debugPrint('''
----|No channels provided, adding default channel.
----|Default channel added.
----|Channels: $_channels
''');
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
--NotificationManager:::getChannel--
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

  /// Show [NotificationWidget] in it's [NotificationQueue].
//   void show(
//     final NotificationWidget notification,
//     final BuildContext context,
//   ) {
//     debugPrint('''
// --NotificationManager:::show--
// ----|Notification: $notification
// ----|Context: $context
// ''');
//     notification.queue.widget.key.currentState?.queue(notification);
//   }

  ///Relocate [NotificationWidget] to a new [QueuePosition]
//   void relocate(
//     final NotificationWidget notification,
//     final QueuePosition newPosition,
//     final BuildContext context,
//   ) {
//     debugPrint('''
// --NotificationManager:::relocate--
// ----|Notification: $notification
// ----|Context: $context
// ----|CurrentPosition: ${notification.queue.position}
// ----|NewPosition: $newPosition
// ----|-----> ${notification.queue.position == newPosition ? 'Same Position, Skipping relocation.' : 'Relocating... .'}
// ''');
//     final relocatingNotification = notification.copyWith(newPosition);
//     final oldQueue = notification.queue;
//     final newQueue = relocatingNotification.queue;
//     if (newQueue == oldQueue) {
//       return;
//     }
//     oldQueue.widget.key.currentState?.dismiss(notification);
//     newQueue.widget.key.currentState?.queue(relocatingNotification);
//   }

  /// Dismiss [NotificationWidget] from it's [NotificationQueue]
//   void dismiss(
//     final NotificationWidget notification,
//     final BuildContext context,
//   ) {
//     debugPrint('''
// --NotificationManager:::dismiss--
// ----|Notification: $notification
// ----|Context: $context
// ''');
//     notification.queue.widget.key.currentState?.dismiss(notification);
//   }
}
