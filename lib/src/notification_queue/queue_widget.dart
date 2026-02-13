part of 'notification_queue.dart';

class QueueWidget extends StatefulWidget {
  const QueueWidget({
    required this.queue,
    super.key,
  });

  final NotificationQueue queue;

  @override
  State<QueueWidget> createState() => QueueWidgetState();
}

class QueueWidgetState extends State<QueueWidget> {
  final _pendingNotifications = Queue<NotificationWidget>();
  final _activeNotifications = ValueNotifier<Set<NotificationWidget>>({});

  @override
  void initState() {
    super.initState();
    // Check mailbox for startup items
    final startupItems = FlutterNotificationQueue.coordinator
        .consumeInitializationQueue(widget.queue.position);
    for (final item in startupItems) {
      _pendingNotifications.add(item);
    }
    _processPending();
  }

  /// Adds a notification to the queue.
  /// Called by QueueCoordinator via GlobalKey.
  void enqueue(final NotificationWidget notification) {
    // 1. Check Active: Update in place (preserve order)
    final currentActive = _activeNotifications.value;
    if (currentActive.any((final n) => n.id == notification.id)) {
      final rebuiltSet = <NotificationWidget>{};
      for (final n in currentActive) {
        if (n.id == notification.id) {
          rebuiltSet.add(notification);
        } else {
          rebuiltSet.add(n);
        }
      }
      _activeNotifications.value = rebuiltSet;
      return;
    }

    // 2. Check Pending: Update in place
    bool isPendingUpdate = false;
    final tempQueue = Queue<NotificationWidget>();
    while (_pendingNotifications.isNotEmpty) {
      final n = _pendingNotifications.removeFirst();
      if (n.id == notification.id) {
        tempQueue.add(notification);
        isPendingUpdate = true;
      } else {
        tempQueue.add(n);
      }
    }
    _pendingNotifications.addAll(tempQueue);

    if (isPendingUpdate) {
      return;
    }

    // 3. New Notification
    _pendingNotifications.add(notification);
    _processPending();
  }

  /// Dismisses a notification.
  /// Called by QueueCoordinator via GlobalKey.
  void dismiss(final NotificationWidget notification) {
    final currentActive = _activeNotifications.value;
    if (currentActive.contains(notification)) {
      final newSet = LinkedHashSet<NotificationWidget>.from(currentActive)
        ..remove(notification);
      _activeNotifications.value = newSet;
    } else {
      _pendingNotifications.removeWhere((final n) => n.id == notification.id);
    }

    _processPending();
    _checkEmpty();
  }

  /// Removes a notification from the queue (for relocation).
  /// Returns true if the notification was found and removed.
  bool remove(final NotificationWidget notification) {
    bool removed = false;
    final currentActive = _activeNotifications.value;

    if (currentActive.contains(notification)) {
      final newSet = LinkedHashSet<NotificationWidget>.from(currentActive)
        ..remove(notification);
      _activeNotifications.value = newSet;
      removed = true;
    }

    if (!removed) {
      final initialLen = _pendingNotifications.length;
      _pendingNotifications.removeWhere((final n) => n.id == notification.id);
      if (_pendingNotifications.length < initialLen) {
        removed = true;
      }
    }

    if (removed) {
      _processPending();
      _checkEmpty();
    }

    return removed;
  }

  void _processPending() {
    final limit = widget.queue.maxStackSize;

    while (_pendingNotifications.isNotEmpty &&
        _activeNotifications.value.length < limit) {
      final notification = _pendingNotifications.removeFirst();
      final newSet =
          LinkedHashSet<NotificationWidget>.from(_activeNotifications.value)
            ..add(notification);
      _activeNotifications.value = newSet;
    }
  }

  void _checkEmpty() {
    if (_activeNotifications.value.isEmpty && _pendingNotifications.isEmpty) {
      // We are empty. Tell coordinator to deactivate us.
      // Post frame callback to avoid mid-build state changes if called during
      // build (unlikely but safe)
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        FlutterNotificationQueue.coordinator
            .unmountQueue(widget.queue.position);
      });
    }
  }

  @override
  Widget build(final BuildContext context) =>
      ValueListenableBuilder<Set<NotificationWidget>>(
        valueListenable: _activeNotifications,
        builder: (final context, final activeNotifications, final child) {
          final pendingCount = _pendingNotifications.length;
          final activeList = activeNotifications.toList();
          return SafeArea(
            child: Container(
              alignment: widget.queue.position.alignment,
              margin: widget.queue.margin,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height *
                      0.6, // Bound overall height
                ),
                child: Column(
                  spacing: widget.queue.spacing,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: widget.queue.mainAxisAlignment,
                  crossAxisAlignment: widget.queue.crossAxisAlignment,
                  verticalDirection: widget.queue.verticalDirection,
                  children: [
                    widget.queue.queueIndicatorBuilder?.call(pendingCount) ??
                        const SizedBox.shrink(),
                    ...activeList.asMap().entries.map((final entry) {
                      final index = entry.key;
                      final notification = entry.value;
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        reverseDuration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeOut,
                        layoutBuilder:
                            (final currentChild, final previousChildren) =>
                                currentChild ?? const SizedBox.shrink(),
                        child: KeyedSubtree(
                          key: ValueKey('${notification.id}_$index'),
                          child: DraggableTransitions(
                            notification: notification,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      );
}
