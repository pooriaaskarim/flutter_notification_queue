import 'package:flutter/material.dart';

import '../../flutter_notification_queue.dart';
import '../utils/logger.dart';
import 'notification_manager/notification_manager.dart';
import 'overlay_manager/overlay_manager.dart';

class NotificationQueueWrapper extends StatefulWidget {
  const NotificationQueueWrapper({
    required this.child,
    super.key,
    this.queues,
    this.channels,
    this.debugMode = false,
  });

  /// Your app's root widget (e.g., MaterialApp)
  final Widget child;

  /// Optional custom queues (defaults to TopCenterQueue)
  final Set<NotificationQueue>? queues;

  /// Optional custom channels (creates a 'default' channel if not provided)
  final Set<NotificationChannel>? channels;

  /// Enable debug prints (package-wide)
  final bool debugMode;

  @override
  State<NotificationQueueWrapper> createState() =>
      _NotificationQueueWrapperState();
}

class _NotificationQueueWrapperState extends State<NotificationQueueWrapper> {
  @override
  void initState() {
    final b = LogBuffer.d
      ?..writeAll(['NotificationQueueWrapper Created State.'])
      ..flush();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final b = LogBuffer.d
      ?..writeAll([
        'NotificationManager ${NotificationManager.initialized ? 'already initialized' : 'not initialized'}.',
        'OverlayManager ${OverlayManager.initialized ? 'already initialized' : 'not initialized'}.',
        'Debug mode: ${widget.debugMode}.',
      ])
      ..flush();

    OverlayManager.configure(context);
    NotificationManager.configure(
      queues: widget.queues,
      channels: widget.channels,
    );
  }

  @override
  Widget build(final BuildContext context) => widget.child;
}
