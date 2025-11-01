part of 'notification_queue.dart';

class QueueWidget extends StatefulWidget {
  const QueueWidget._({
    required this.parentQueue,
    required final GlobalKey<QueueWidgetState> key,
  }) : _key = key;
  final GlobalKey<QueueWidgetState> _key;

  @override
  GlobalKey<QueueWidgetState> get key => _key;
  final NotificationQueue parentQueue;

  @override
  State<StatefulWidget> createState() => QueueWidgetState();
}

class QueueWidgetState extends State<QueueWidget> {
  final _pendingNotifications = ValueNotifier(
    LinkedHashSet<NotificationWidget>(
      equals: (final n1, final n2) => n1.id == n2.id,
    ),
  );
  final _activeNotifications = ValueNotifier(
    LinkedHashSet<NotificationWidget>(
      equals: (final n1, final n2) => n1.id == n2.id,
    ),
  );
  final _listKey = GlobalKey<AnimatedListState>();

  void queue(final NotificationWidget notification) {
    debugPrint('''
------${widget.parentQueue}:::QueueWidgetState:::queue------
--------|Notification: $notification
--------|From Context: $context''');
    _pendingNotifications.value.add(notification);
    _processQueue();
  }

  void _processQueue() {
    debugPrint('''
------${widget.parentQueue}:::QueueWidgetState:::_processQueue------''');
    while (_pendingNotifications.value.isNotEmpty &&
        _activeNotifications.value.length < widget.parentQueue.maxStackSize) {
      debugPrint('''
--------Processing Queue InProgress--------''');
      final latestNotification =
          _pendingNotifications.value.toList().removeAt(0);
      _activeNotifications.value.add(
        latestNotification,
      ); // Insert at top for stack behavior
      _listKey.currentState?.insertItem(0);
    }
  }

  void dismiss(
    final NotificationWidget notification,
  ) {
    debugPrint('''
------${widget.parentQueue}:::QueueWidgetState:::dismiss------
--------|Removing Notification: $notification''');
    final activeIndex = _activeNotifications.value
        .toList()
        .indexWhere((final n) => n.id == notification.id);
    if (activeIndex != -1) {
      final removed = _activeNotifications.value.remove(notification);
      _listKey.currentState?.removeItem(
        activeIndex,
        (final context, final animation) => SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: widget.parentQueue.slideTransitionOffset * -1,
          ).animate(animation),
          child: notification,
        ),
        duration: const Duration(milliseconds: 300),
      );
      debugPrint('''
--------|Notification Removed from Active.
''');
    } else {
      final removedFromPending =
          _pendingNotifications.value.remove(notification);
      if (removedFromPending) {
        debugPrint('''
--------|Notification Removed from Pending.
''');
      } else {
        debugPrint('''
--------|Notification Not Found. Already Dismissed????
''');
      }
    }
    _safeDispose();
  }

  void relocate(
    final NotificationWidget notification,
    final QueuePosition newPosition,
  ) {
    debugPrint('''
------${widget.parentQueue}:::QueueWidgetState:::relocate------
--------|Notification: $notification
--------|RelocatingTo: $newPosition
''');
    final activeIndex = _activeNotifications.value
        .toList()
        .indexWhere((final n) => n.id == notification.id);
    bool removed = false;
    if (activeIndex != -1) {
      _activeNotifications.value.toList().removeAt(activeIndex);
      _listKey.currentState?.removeItem(
        activeIndex,
        (final context, final animation) => const SizedBox.shrink(),
        duration: Duration.zero,
      );
      removed = true;
    } else {
      removed = _pendingNotifications.value.toList().remove(notification);
    }
    if (removed) {
      debugPrint('''
--------|Notification Removed.
''');
      final newQueue = NotificationManager.instance.getQueue(newPosition);
      final newNotification = notification.copyWith(newPosition);
      newQueue.widget.key.currentState?.queue(newNotification);
    } else {
      debugPrint('''
--------|Notification Not Found.
''');
    }
    _safeDispose();
  }

  bool _safeDispose() {
    debugPrint('''
------${widget.parentQueue}:::QueueWidgetState:::safeDispose------''');
    if (_pendingNotifications.value.toList().isEmpty &&
        _activeNotifications.value.toList().isEmpty) {
      debugPrint('''
--------|No Pending Notifications And No Active Notifications.
--------|Disposing... .
''');
      dispose();
      return true;
    } else {
      debugPrint('''
--------|Has Pending/Active Notifications.
--------|Not Disposing.
''');
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    OverlayManager.instance.show(
      widget.parentQueue.toString(),
      OverlayEntryData(
        builder: (final context) => widget,
        position: AlignedPosition(widget.parentQueue.position.alignment),
      ),
    );
  }

  @override
  void dispose() {
    widget.parentQueue._queueWidget = null;
    _activeNotifications.dispose();
    _pendingNotifications.dispose();

    OverlayManager.instance.hide(widget.parentQueue.toString());
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    debugPrint('''
------${widget.parentQueue}:::QueueWidgetState:::build------''');
    return ValueListenableBuilder(
      valueListenable: _pendingNotifications,
      builder: (final context, final pendingNotifications, final child) {
        final pendingNotificationsCount = pendingNotifications.length;
        return SafeArea(
          child: Container(
            alignment: widget.parentQueue.position.alignment,
            margin: widget.parentQueue.margin,
            child: Column(
              spacing: widget.parentQueue.spacing,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: widget.parentQueue.mainAxisAlignment,
              crossAxisAlignment: widget.parentQueue.crossAxisAlignment,
              verticalDirection: widget.parentQueue.verticalDirection,
              children: [
                widget.parentQueue.queueIndicatorBuilder?.call(
                      pendingNotificationsCount,
                    ) ??
                    const SizedBox.shrink(),
                ValueListenableBuilder(
                  valueListenable: _activeNotifications,
                  builder:
                      (final context, final activeNotifications, final child) =>
                          AnimatedList.separated(
                    key: _listKey,
                    initialItemCount: activeNotifications.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (final context, final index, final animation) {
                      final notification = activeNotifications.toList()[index];
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: widget.parentQueue.slideTransitionOffset,
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: FadeTransition(
                          opacity: animation,
                          child: DraggableTransitions(
                            notification: notification,
                          ),
                        ),
                      );
                    },
                    separatorBuilder:
                        (final context, final index, final animation) =>
                            SizedBox(
                      height: widget.parentQueue.spacing,
                    ),
                    removedSeparatorBuilder:
                        (final context, final index, final animation) =>
                            SizedBox(
                      height: widget.parentQueue.spacing,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
