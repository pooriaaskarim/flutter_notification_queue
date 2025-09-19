import 'dart:async';
import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../in_app_notifications.dart';
import 'in_app_notification_action.dart';
import 'utils/utils.dart';

part 'in_app_notification.dart';
part 'extensions.dart';

InAppNotificationManager get _instance => InAppNotificationManager.instance;

class InAppNotificationManager {
  InAppNotificationManager._();
  static final InAppNotificationManager instance = InAppNotificationManager._();

  final _queue = Queue<InAppNotification>();
  final _activeNotifications = ValueNotifier(<InAppNotification>[]);

  final ValueNotifier<InAppNotificationConfig> _configNotifier =
      ValueNotifier(const InAppNotificationConfig());

  InAppNotificationConfig get config => _configNotifier.value;

  set config(final InAppNotificationConfig newConfig) =>
      _configNotifier.value = newConfig;

  int get maxStackSize => config.maxStackSize;

  OverlayEntry? _overlayEntry;

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

  Widget _buildQueue(final BuildContext context) => ValueListenableBuilder(
        valueListenable: _configNotifier,
        builder: (final context, final config, final child) =>
            ValueListenableBuilder<List<InAppNotification>>(
          valueListenable: _activeNotifications,
          builder: (final context, final activeNotifications, final _) =>
              SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: config.position.crossAxisAlignment,
              verticalDirection: config.position.verticalDirection,
              children: [
                if (_queue.isNotEmpty)
                  config.stackIndicatorBuilder
                          ?.call(context, _queue.length, config) ??
                      Align(
                        alignment: config.position.alignment,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+ ${_queue.length} more',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                ...activeNotifications
                    .map((final inAppNotification) => inAppNotification),
              ],
            ),
          ),
        ),
      );
}
