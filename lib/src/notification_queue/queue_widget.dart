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

class QueueWidgetState extends State<QueueWidget>
    with TickerProviderStateMixin {
  final _pendingNotifications = Queue<NotificationWidget>();
  final _items = <_NotificationItemState>[];

  @override
  void initState() {
    super.initState();
    final startupItems = FlutterNotificationQueue.coordinator
        .consumeInitializationQueue(widget.queue.position);
    for (final item in startupItems) {
      _pendingNotifications.add(item);
    }
    _processPending();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.controller.dispose();
    }
    super.dispose();
  }

  void enqueue(final NotificationWidget notification) {
    // 1. Update Existing Active
    final existingIndex = _indexOf(notification.id);
    if (existingIndex != -1) {
      setState(() {
        _items[existingIndex].widget = notification;
      });
      return;
    }

    // 2. Update Pending (in-place)
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

    // 3. Enqueue New
    _pendingNotifications.add(notification);
    _processPending();
  }

  void dismiss(final NotificationWidget notification) {
    final index = _indexOf(notification.id);
    if (index != -1) {
      _animateExit(_items[index]);
    } else {
      _pendingNotifications.removeWhere((final n) => n.id == notification.id);
      _checkEmpty();
    }
  }

  bool remove(final NotificationWidget notification) {
    bool removed = false;
    final index = _indexOf(notification.id);

    if (index != -1) {
      _removeItemImmediate(index);
      removed = true;
    } else {
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

  /// Moves [notification] to [targetIndex] within the active items list.
  ///
  /// Has no effect if [notification] is not found in the active list.
  /// Dropping at the current index is allowed and resolves as a no-op.
  void reorder(
    final NotificationWidget notification,
    final int targetIndex,
  ) {
    final currentIndex = _indexOf(notification.id);
    if (currentIndex == -1) {
      return;
    }
    if (currentIndex == targetIndex) {
      // Dropped at own original position — nothing to move, but the gesture
      // completed successfully so we do not suppress the interaction.
      return;
    }

    setState(() {
      final item = _items.removeAt(currentIndex);
      // After removal the list is shorter, so clamp the insertion index.
      final clampedTarget = targetIndex.clamp(0, _items.length);
      _items.insert(clampedTarget, item);
    });
  }

  /// The number of currently active (non-pending) notifications.
  int get itemCount => _items.length;

  /// The active-list index of [notification], or -1 if not found.
  int indexOf(final NotificationWidget notification) =>
      _indexOf(notification.id);

  /// The [GlobalKey]s of active notification widgets, in stack order.
  ///
  /// Used by the reorder feedback layer to query each notification's
  /// [RenderBox] position for slot anchor computation.
  List<GlobalKey> get itemGlobalKeys =>
      _items.map((final item) => item.globalKey).toList();

  void _processPending() {
    if (_pendingNotifications.isEmpty) {
      return;
    }

    final limit = widget.queue.maxStackSize;
    // Count only non-exiting items towards the limit?
    // Or count all? If we count all, we wait for exit to finish.
    // Let's count all to avoid visual overflow.
    if (_items.length < limit) {
      final notification = _pendingNotifications.removeFirst();
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
        reverseDuration: const Duration(milliseconds: 200),
      );

      final item = _NotificationItemState(
        widget: notification,
        controller: controller,
      );

      setState(() {
        _items.add(item);
      });

      controller.forward();
    }
  }

  int _indexOf(final String id) =>
      _items.indexWhere((final item) => item.widget.id == id);

  void _animateExit(final _NotificationItemState item) {
    if (item.status == _ItemStatus.exiting) {
      return;
    }

    item.status = _ItemStatus.exiting;
    item.controller.reverse().then((final _) {
      if (mounted) {
        _removeItemImmediate(_items.indexOf(item));
        _processPending();
        _checkEmpty();
      }
    });
  }

  void _removeItemImmediate(final int index) {
    if (index == -1) {
      return;
    }
    setState(() {
      final item = _items.removeAt(index);
      item.controller.dispose();
    });
  }

  void _checkEmpty() {
    if (_items.isEmpty && _pendingNotifications.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        if (mounted) {
          FlutterNotificationQueue.coordinator
              .unmountQueue(widget.queue.position);
        }
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final pendingCount = _pendingNotifications.length;
    return SafeArea(
      child: Container(
        alignment: widget.queue.position.alignment,
        margin: widget.queue.margin,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            spacing: 0, // We handle spacing in the wrapper
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: widget.queue.mainAxisAlignment,
            crossAxisAlignment: widget.queue.crossAxisAlignment,
            verticalDirection: widget.queue.verticalDirection,
            children: [
              widget.queue.queueIndicatorBuilder?.call(pendingCount) ??
                  const SizedBox.shrink(),
              for (final item in _items) _buildItem(item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(final _NotificationItemState item) {
    final alignment =
        widget.queue.verticalDirection == VerticalDirection.down ? -1.0 : 1.0;

    final isLast = item == _items.last;
    final spacing = isLast ? 0.0 : widget.queue.spacing;

    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: item.controller,
        curve: Curves.fastOutSlowIn,
      ),
      axisAlignment: alignment,
      child: Align(
        alignment: widget.queue.position.alignment,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: widget.queue.verticalDirection == VerticalDirection.down
                ? spacing
                : 0,
            top: widget.queue.verticalDirection == VerticalDirection.up
                ? spacing
                : 0,
          ),
          child: widget.queue.transition.build(
            context,
            item.controller,
            widget.queue.position,
            KeyedSubtree(
              key: item.globalKey,
              child: DraggableTransitions(
                notification: item.widget,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ItemStatus { entering, exiting }

class _NotificationItemState {
  _NotificationItemState({
    required this.widget,
    required this.controller,
  });

  NotificationWidget widget;
  final AnimationController controller;
  final GlobalKey globalKey = GlobalKey();
  _ItemStatus status = _ItemStatus.entering;
}
