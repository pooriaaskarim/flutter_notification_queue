import 'dart:collection';

import 'package:flutter/material.dart';

import '../../flutter_notification_queue.dart';
import '../notification/notification.dart';

part 'notification_queue.dart';
part 'type_defs.dart';
part 'extensions.dart';

class QueueManager extends StatefulWidget {
  const QueueManager({
    required this.config,
    super.key,
  });

  final NotificationQueue config;

  @override
  State<QueueManager> createState() => _QueueManagerState();
}

class _QueueManagerState extends State<QueueManager> {
  final _queue = Queue<NotificationWidget>();

  final _activeNotifications = ValueNotifier(<NotificationWidget>[]);

  OverlayEntry? _overlayEntry;

  void show(
    final NotificationWidget quetification,
    final BuildContext context,
  ) {
    _queue.add(quetification);
    _processQueue(context);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;

    super.dispose();
  }

  void _processQueue(final BuildContext context) {
    debugPrint('''
---NotificationQueue at ${widget.config.alignment}: _processQueue Called---''');
    while (_queue.isNotEmpty &&
        _activeNotifications.value.length < widget.config.maxStackSize) {
      debugPrint('''
---Processing Queue InProgress------
---Queue: ${_queue.length}
---Active Notifications: ${_activeNotifications.value.length}''');
      final latestNotification = _queue.removeFirst();

      _activeNotifications.value = [
        ..._activeNotifications.value,
        latestNotification,
      ];

      if (_overlayEntry == null) {
        debugPrint('''
------Inserting OverlayEntry
''');
        _overlayEntry = OverlayEntry(
          builder: (final innerContext) => Align(
            alignment: widget.config.alignment,
            child: build(context),
          ),
        );
        Overlay.of(context).insert(_overlayEntry!);
      } else {
        debugPrint('''
------Updating OverlayEntry
''');
        _activeNotifications.notifyListeners();
      }
    }
    _checkDisposal();
  }

  void _checkDisposal() {
    debugPrint('''
---NotificationQueue at ${widget.config.alignment}: _checkDisposal Called---
---Queue: ${_queue.length}
---Active Notifications: ${_activeNotifications.value.length}''');

    if (_queue.isEmpty && _activeNotifications.value.isEmpty) {
      debugPrint('''
------Disposed OverlayEntry
''');
      dispose();
    } else {
      debugPrint('''
------Skipped Disposing OverlayEntry
''');
    }
  }

  @override
  Widget build(final BuildContext context) {
    debugPrint('''
---NotificationQueue at ${widget.config.alignment}: build Called---''');

    return ValueListenableBuilder<List<NotificationWidget>>(
      valueListenable: _activeNotifications,
      builder: (final context, final activeNotifications, final _) {
        debugPrint('''
---NotificationQueue at ${widget.config.alignment}: _build:::Active Notifications Updated---
---Queue: ${_queue.length}
---Active Notifications: ${_activeNotifications.value.length}''');

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: widget.config.crossAxisAlignment,
            verticalDirection: widget.config.verticalDirection,
            children: [
              if (widget.config.queueIndicatorBuilder != null &&
                  _queue.isNotEmpty)
                widget.config.queueIndicatorBuilder!.call(
                  context,
                  _queue.length,
                  _activeNotifications.value.length,
                ),
              ...activeNotifications
                  .map((final quetification) => quetification),
            ],
          ),
        );
      },
    );
  }
}
