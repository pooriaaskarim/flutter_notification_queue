import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'in_app_notification_action.dart';
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
    _queue.add(inAppNotification);
    _processQueue(context);
  }

  void _processQueue(final BuildContext context) {
    while (
        _queue.isNotEmpty && _activeNotifications.value.length < maxStackSize) {
      final latestNotification = _queue.removeFirst();

      _activeNotifications.value = [
        ..._activeNotifications.value,
        latestNotification,
      ];
      _activeNotifications.notifyListeners();

      if (_overlayEntry == null) {
        _overlayEntry =
            OverlayEntry(builder: (final context) => _buildQueue(context));
        Overlay.of(context).insert(_overlayEntry!);
      }

      if (_queue.isEmpty && _activeNotifications.value.isEmpty) {
        _overlayEntry?.remove();
        _overlayEntry?.dispose();
        _overlayEntry = null;
      }
    }
  }

  Widget _buildQueue(final BuildContext context) =>
      ValueListenableBuilder<List<InAppNotification>>(
        valueListenable: _activeNotifications,
        builder: (final context, final activeNotifications, final _) =>
            SafeArea(
          child: Column(
            children: [
              if (_queue.isNotEmpty)
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Container(
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
        ),
      );
}
