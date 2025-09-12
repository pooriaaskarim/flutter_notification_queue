import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../in_app_notifications.dart';
import 'in_app_notification_action.dart' show InAppNotificationActionType;
import 'utils/utils.dart';

part 'in_app_notification.dart';

class InAppNotificationManager {
  InAppNotificationManager._();
  static final InAppNotificationManager instance = InAppNotificationManager._();

  final _queue = Queue<InAppNotification>();
  final _activeNotifications = ValueNotifier(<InAppNotification>[]);

  OverlayEntry? _overlayEntry;
  final int maxStackSize = 2;

  void show(
    final InAppNotification inAppNotification,
    final BuildContext context,
  ) {
    debugPrint('''
---InAppNotificationManager---Called _show---
------------------------------Queue: ${_queue.length}
------------------------------Active Notifications: ${_activeNotifications.value.length}
''');
    _queue.add(inAppNotification);
    _processQueue(context);
  }

  void _processQueue(final BuildContext context) {
    debugPrint('''
---InAppNotificationManager---Called _processQueue---
------------------------------Queue: ${_queue.length}
------------------------------Active Notifications: ${_activeNotifications.value.length}
''');

    WidgetsBinding.instance.addPostFrameCallback((final _) {
      while (_queue.isNotEmpty &&
          _activeNotifications.value.length < maxStackSize) {
        final latestNotification = _queue.removeFirst();

        _activeNotifications.value = [
          ..._activeNotifications.value,
          latestNotification,
        ];

        if (_overlayEntry == null) {
          _overlayEntry =
              OverlayEntry(builder: (final context) => _buildQueue(context));
          Overlay.of(context).insert(_overlayEntry!);
        } else {
          _activeNotifications.notifyListeners(); // Rebuild stack
        }

        if (_queue.isEmpty && _activeNotifications.value.isEmpty) {
          _overlayEntry?.remove();
          _overlayEntry?.dispose();
          _overlayEntry = null;
        }
      }
    });
  }

  Widget _buildQueue(final BuildContext context) {
    debugPrint('''
---InAppNotificationManager---Called _buildQueue---
---------------------------Queue: ${_queue.length}
---------------------------Active Notifications: ${_activeNotifications.value.length}
''');

    return ValueListenableBuilder<List<InAppNotification>>(
      valueListenable: _activeNotifications,
      builder: (final context, final activeNotifications, final _) {
        debugPrint('''
---InAppNotificationManager---Notified _buildQueue ListenableBuilder---
-----------------------------Queue: ${_queue.length}
-----------------------------Active Notifications: ${_activeNotifications.value.length}
''');
        if (activeNotifications.isEmpty) {
          return const SizedBox.shrink();
        }
        return SafeArea(
          child: Column(
            children: [
              if (_queue.isNotEmpty)
                Center(
                  child: Container(
                    alignment: AlignmentDirectional.centerStart,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+ ${_queue.length} more',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ...activeNotifications
                  .map((final inAppNotification) => inAppNotification),
            ],
          ),
        );
      },
    );
  }

  // void _removeNotification(
  //   final InAppNotification widget,
  //   final BuildContext context,
  // ) {
  //   final index = _activeNotifications.value.indexWhere(
  //     (final activeNotification) => activeNotification == widget,
  //   );
  //
  //   if (index == -1) {
  //     return;
  //   }
  //   debugPrint('Removing notification at index: $index');
  //   // _activeNotifications.value =
  //   //     List.from(_activeNotifications.value..removeAt(index));
  //   // // _activeNotifications.value.remove(widget);
  //   // _activeNotifications.notifyListeners(); // Rebuild
  //
  //   // // Update positions of remaining (slide up)
  //   // for (var i = index; i < _activeNotifications.value.length; i++) {
  //   //   // _activeNotifications.value[i].verticalAlignmentNotifier.value =
  //   //   //     _initialVerticalPosition(i);
  //   // }
  //
  //   // if (_activeNotifications.value.isEmpty) {
  //   //   _overlayEntry?.remove();
  //   //   _overlayEntry?.dispose();
  //   //   _overlayEntry = null;
  //   // }
  //
  //   // _processQueue(context);
  // }
}
