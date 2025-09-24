part of 'notification_queue.dart';

class QueueManager {
  QueueManager(
    this.notificationQueue,
  );

  final NotificationQueue notificationQueue;

  final pendingNotifications = Queue<NotificationWidget>();

  final activeNotifications = ValueNotifier(<NotificationWidget>[]);

  OverlayEntry? _overlayEntry;

  Future<void> queue(
    final NotificationWidget notification,
    final BuildContext context,
  ) async {
    debugPrint('''
---------$notificationQueue:::QueueManager:::queue---------
------------Notification: $notification
------------From Context: $context''');
    if (notification.id != null) {
      debugPrint('''
------------Notification ID: ${notification.id}
------------Checking Active Notifications... .''');
      final activeIndex = activeNotifications.value
          .indexWhere((final n) => n.id == notification.id);
      if (activeIndex != -1) {
        debugPrint('''
------------Notification Already Active at Index: $activeIndex.
------------Updating Notification.
''');
        activeNotifications.value[activeIndex] =
            notification; // Replace (Flutter rebuilds)
        activeNotifications.notifyListeners();
        return;
      }
      debugPrint('''
------------No Active Notification Found.
------------Checking Pending Notifications... .''');
      final pendingIndex = pendingNotifications
          .toList()
          .indexWhere((final n) => n.id == notification.id);
      if (pendingIndex != -1) {
        debugPrint('''
------------Notification Already Pending at Index: $pendingIndex.
------------Updating Notification.
''');
        pendingNotifications.toList()[pendingIndex] = notification;
        return;
      }
      debugPrint('''
------------No Pending Notification Found.''');
    }
    debugPrint('''
------------Adding Notification to Pending Queue.
''');
    pendingNotifications.add(notification);
    _processQueue(context);
  }

  void _processQueue(final BuildContext context) {
    debugPrint('''
---------$notificationQueue:::QueueManager:::_processQueue---------''');
    while (pendingNotifications.isNotEmpty &&
        activeNotifications.value.length < notificationQueue.maxStackSize) {
      debugPrint('''
------------Processing Queue InProgress------------
''');
      final latestNotification = pendingNotifications.removeFirst();

      activeNotifications.value = [
        ...activeNotifications.value,
        latestNotification,
      ];

      if (_overlayEntry == null) {
        debugPrint('''
------------Inserting OverlayEntry
''');
        _overlayEntry = OverlayEntry(
          builder: (final innerContext) => _buildQueue(context),
        );
        Overlay.of(context).insert(_overlayEntry!);
      } else {
        debugPrint('''
------------Updating OverlayEntry
''');
        activeNotifications.notifyListeners();
      }
    }
  }

  void dismiss(
    final NotificationWidget notification,
    final BuildContext context,
  ) {
//     debugPrint('''
// ---------$notificationQueue:::QueueManager:::dismiss---------
// ------------Removing Notification: $notification
// ------------From Context: $context
// ''');
//     final index = activeNotifications.value.indexOf(notification);
//     if (index == -1) {
//       debugPrint('''
// ------------Notification Not Found. Already Dismissed????
// ''');
//       return;
//     } else {
//       activeNotifications
//         ..value.removeAt(index)
//         ..notifyListeners();
//       _processQueue(context);
//
//       debugPrint('''
// ------------Notification Removed at Index: $index.
// ''');
//     }

    debugPrint('''
---------$notificationQueue:::QueueManager:::dismiss---------
------------Removing Notification: $notification
------------From Context: $context''');
    final removed = activeNotifications.value.remove(notification);
    if (removed) {
      debugPrint('''
------------Notification Removed.
''');
      activeNotifications.notifyListeners();
    } else {
      debugPrint('''
------------Notification Not Found. Already Dismissed????
''');
    }

    final disposed = safeDispose();
    if (!disposed) {
      _processQueue(context);
    }
  }

  bool safeDispose() {
    debugPrint('''
---------$notificationQueue:::QueueManager:::safeDispose---------
''');
    if (pendingNotifications.isEmpty && activeNotifications.value.isEmpty) {
      debugPrint('''
------------No Pending Notifications And No Active Notifications.
------------Disposing... .
''');
      dispose();
      return true;
    } else {
      debugPrint('''
------------Has Pending/Active Notifications.
------------Not Disposing.
''');
      return false;
    }
  }

  void dispose() {
    debugPrint('''
---------$notificationQueue:::QueueManager:::dispose---------
------------Disposing OverlayEntry.
------------Disposing QueueManager.
------------Done.
''');
    activeNotifications.dispose();
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;

    notificationQueue._queueManager = null;
  }

  Widget _buildQueue(final BuildContext context) {
    debugPrint('''
---------$notificationQueue:::QueueManager:::_buildQueue---------''');
    return ValueListenableBuilder<List<NotificationWidget>>(
      valueListenable: activeNotifications,
      builder: (final context, final activeNotifications, final _) {
        final pendingNotificationsCount = pendingNotifications.length;
        debugPrint('''
---------$notificationQueue:::QueueManager:::_buildQueue:::InnerBuilder---------
''');

        return SafeArea(
          child: Container(
            alignment: notificationQueue.position.alignment,
            margin: notificationQueue.margin,
            child: Column(
              spacing: notificationQueue.spacing,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: notificationQueue.position.mainAxisAlignment,
              crossAxisAlignment: notificationQueue.position.crossAxisAlignment,
              verticalDirection: notificationQueue.position.verticalDirection,
              children: [
                notificationQueue.queueIndicatorBuilder?.call(
                      pendingNotificationsCount,
                    ) ??
                    const SizedBox.shrink(),
                ...activeNotifications
              ],
            ),
          ),
        );
      },
    );
  }
}
