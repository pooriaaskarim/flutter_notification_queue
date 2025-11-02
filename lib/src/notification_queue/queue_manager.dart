// part of 'notification_queue.dart';
//
// class QueueManager {
//   QueueManager(
//     this.notificationQueue,
//   );
//
//   final NotificationQueue notificationQueue;
//
//   final pendingNotifications = Queue<NotificationWidget>();
//
//   final _activeNotifications = ValueNotifier(<NotificationWidget>[]);
//
//   OverlayEntry? _overlayEntry;
//
//   Future<void> queue(
//     final NotificationWidget notification,
//     final BuildContext context,
//   ) async {
//     AppDebugger.log('''
// ------$notificationQueue:::QueueManager:::queue------
// --------|Notification: $notification
// --------|From Context: $context''');
//     AppDebugger.log('''
// --------|Notification ID: ${notification.id}
// --------|Checking Active Notifications... .''');
//     final activeIndex = _activeNotifications.value
//         .indexWhere((final n) => n.id == notification.id);
//     if (activeIndex != -1) {
//       AppDebugger.log('''
// --------|Notification Already Active at Index: $activeIndex.
// --------|Updating Notification.
// ''');
//       _activeNotifications.value[activeIndex] =
//           notification; // Replace (Flutter rebuilds)
//       _activeNotifications.notifyListeners();
//       return;
//     }
//     AppDebugger.log('''
// --------|No Active Notification Found.
// --------|Checking Pending Notifications... .''');
//     final pendingIndex = pendingNotifications
//         .toList()
//         .indexWhere((final n) => n.id == notification.id);
//     if (pendingIndex != -1) {
//       AppDebugger.log('''
// --------|Notification Already Pending at Index: $pendingIndex.
// --------|Updating Notification.
// ''');
//       pendingNotifications.toList()[pendingIndex] = notification;
//       return;
//     }
//     AppDebugger.log('''
// --------|No Pending Notification Found.''');
//     AppDebugger.log('''
// --------|Adding Notification to Pending Queue.
// ''');
//     pendingNotifications.add(notification);
//     processQueue(context);
//   }
//
//   void processQueue(final BuildContext context) {
//     AppDebugger.log('''
// ------$notificationQueue:::QueueManager:::_processQueue------''');
//     while (pendingNotifications.isNotEmpty &&
//         _activeNotifications.value.length < notificationQueue.maxStackSize) {
//       AppDebugger.log('''
// --------Processing Queue InProgress--------''');
//       final latestNotification = pendingNotifications.removeFirst();
//
//       _activeNotifications.value = [
//         ..._activeNotifications.value,
//         latestNotification,
//       ];
//
//       if (_overlayEntry == null) {
//         AppDebugger.log('''
// --------|Inserting OverlayEntry
// ''');
//         _overlayEntry = OverlayEntry(
//           builder: (final innerContext) => _buildQueue(context),
//         );
//         Overlay.of(context).insert(_overlayEntry!);
//       } else {
//         AppDebugger.log('''
// --------|Updating OverlayEntry
// ''');
//         _activeNotifications.notifyListeners();
//       }
//     }
//   }
//
//   void dismiss(
//     final NotificationWidget notification,
//     final BuildContext context,
//   ) {
//     AppDebugger.log('''
// ------$notificationQueue:::QueueManager:::dismiss------
// --------|Removing Notification: $notification
// --------|From Context: $context''');
//     final removed = _activeNotifications.value.remove(notification);
//     if (removed) {
//       AppDebugger.log('''
// --------|Notification Removed.
// ''');
//       _activeNotifications.notifyListeners();
//     } else {
//       AppDebugger.log('''
// --------|Notification Not Found. Already Dismissed????
// ''');
//     }
//
//     final disposed = safeDispose();
//     if (!disposed) {
//       processQueue(context);
//     }
//   }
//
//   void relocate(
//     final NotificationWidget notification,
//     final NotificationQueue newQueue,
//     final BuildContext context,
//   ) {
//     AppDebugger.log('''
// ------$notificationQueue:::QueueManager:::relocate------
// --------|Notification: $notification
// --------|RelocatingTo: $newQueue
// --------|Context: $context
// ''');
//
//     final removed = _activeNotifications.value.remove(notification);
//     if (removed) {
//       AppDebugger.log('''
// --------|Notification Removed.
// ''');
//       newQueue.manager.queue(notification, context);
//       _activeNotifications.notifyListeners();
//     } else {
//       AppDebugger.log('''
// --------|Notification Not Found.
// ''');
//     }
//
//     final disposed = safeDispose();
//     if (!disposed) {
//       processQueue(context);
//     }
//   }
//
//   bool safeDispose() {
//     AppDebugger.log('''
// ------$notificationQueue:::QueueManager:::safeDispose------''');
//     if (pendingNotifications.isEmpty && _activeNotifications.value.isEmpty) {
//       AppDebugger.log('''
// --------|No Pending Notifications And No Active Notifications.
// --------|Disposing... .
// ''');
//       dispose();
//       return true;
//     } else {
//       AppDebugger.log('''
// --------|Has Pending/Active Notifications.
// --------|Not Disposing.
// ''');
//       return false;
//     }
//   }
//
//   void dispose() {
//     _activeNotifications.dispose();
//     _overlayEntry?.remove();
//     _overlayEntry?.dispose();
//     _overlayEntry = null;
//     notificationQueue._queueManager = null;
//
//     AppDebugger.log('''
// ------$notificationQueue:::QueueManager:::dispose------
// --------|Disposed OverlayEntry.
// --------|Disposed QueueManager.
// ''');
//   }
//
//   Widget _buildQueue(final BuildContext context) {
//     AppDebugger.log('''
// ------$notificationQueue:::QueueManager:::_buildQueue------''');
//     return ValueListenableBuilder<List<NotificationWidget>>(
//       valueListenable: _activeNotifications,
//       builder: (final context, final activeNotifications, final _) {
//         final pendingNotificationsCount = pendingNotifications.length;
//         AppDebugger.log('''
// --------$notificationQueue:::QueueManager:::_buildQueue:::InnerBuilder--------
// ''');
//         return SafeArea(
//           child: Container(
//             alignment: notificationQueue.position.alignment,
//             margin: notificationQueue.margin,
//             child: Column(
//               spacing: notificationQueue.spacing,
//               mainAxisSize: MainAxisSize.min,
//               mainAxisAlignment: notificationQueue.mainAxisAlignment,
//               crossAxisAlignment: notificationQueue.crossAxisAlignment,
//               verticalDirection: notificationQueue.verticalDirection,
//               children: [
//                 notificationQueue.queueIndicatorBuilder?.call(
//                       pendingNotificationsCount,
//                     ) ??
//                     const SizedBox.shrink(),
//                 ...activeNotifications.map(
//                   (final notification) => DraggableTransitions(
//                     notification: notification,
//                     hapticFeedbackOnStart: true,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
