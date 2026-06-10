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
  final List<_NotificationItemState> _items = [];

  /// Key attached to the inner Column to measure the queue's exact visual
  /// bounds.
  final GlobalKey _listKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final startupItems = FlutterNotificationQueue.coordinator
        .consumeInitializationQueue(widget.queue.position);
    for (final item in startupItems) {
      _pendingNotifications.add(item);
    }
    _sortPending();
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

    _sortPending();

    if (isPendingUpdate) {
      return;
    }

    // 3. Enqueue New
    if (widget.queue.maxPendingSize != null &&
        _pendingNotifications.length >= widget.queue.maxPendingSize!) {
      if (widget.queue.overflowStrategy ==
          QueueOverflowStrategy.discardOldest) {
        var lowestPriority = NotificationPriority.critical;
        for (final item in _pendingNotifications) {
          if (item.resolvedPriority.index < lowestPriority.index) {
            lowestPriority = item.resolvedPriority;
          }
        }
        final oldestOfLowest = _pendingNotifications.firstWhere(
          (final item) => item.resolvedPriority == lowestPriority,
        );
        _pendingNotifications.remove(oldestOfLowest);
        FlutterNotificationQueue.coordinator.emitOverflowed(
          queue: widget.queue,
          dropped: oldestOfLowest,
        );
        _pendingNotifications.add(notification);
      } else {
        FlutterNotificationQueue.coordinator.emitOverflowed(
          queue: widget.queue,
          dropped: notification,
        );
        return;
      }
    } else {
      _pendingNotifications.add(notification);
    }
    _sortPending();
    _triagePriorityEviction();
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

  /// The list of currently active notifications in this queue.
  List<NotificationWidget> get activeNotifications =>
      _items.map((final item) => item.widget).toList();

  /// The active-list index of [notification], or -1 if not found.
  int indexOf(final NotificationWidget notification) =>
      _indexOf(notification.id);

  /// The [GlobalKey]s of active notification widgets, in stack order.
  ///
  /// Used by the reorder feedback layer to query each notification's
  /// [RenderBox] position for slot anchor computation.
  List<GlobalKey> get itemGlobalKeys =>
      _items.map((final item) => item.globalKey).toList();

  /// The [RenderBox] of the inner column containing the notifications.
  ///
  /// Used to compute the boundary for [ReorderAndRelocate] escape detection.
  RenderBox? get listRenderBox {
    final ctx = _listKey.currentContext;
    if (ctx == null) {
      return null;
    }
    return ctx.findRenderObject() as RenderBox?;
  }

  void _processPending() {
    final limit = widget.queue.maxStackSize;
    while (_pendingNotifications.isNotEmpty && _items.length < limit) {
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

  void _sortPending() {
    final list = _pendingNotifications.toList()
      ..sort(
        (final a, final b) =>
            b.resolvedPriority.index.compareTo(a.resolvedPriority.index),
      );
    _pendingNotifications
      ..clear()
      ..addAll(list);
  }

  void _triagePriorityEviction() {
    if (_items.length < widget.queue.maxStackSize ||
        _pendingNotifications.isEmpty) {
      return;
    }
    final highestPending = _pendingNotifications.first;

    _NotificationItemState? lowestActiveItem;
    for (final item in _items) {
      if (item.status == _ItemStatus.exiting) {
        continue;
      }
      if (lowestActiveItem == null ||
          item.widget.resolvedPriority <
              lowestActiveItem.widget.resolvedPriority) {
        lowestActiveItem = item;
      }
    }

    if (lowestActiveItem != null &&
        highestPending.resolvedPriority >
            lowestActiveItem.widget.resolvedPriority) {
      final evictedWidget = lowestActiveItem.widget;
      lowestActiveItem.status = _ItemStatus.exiting;
      lowestActiveItem.controller.reverse().then((final _) {
        if (mounted) {
          final itemIndex = _items.indexOf(lowestActiveItem!);
          if (itemIndex != -1) {
            _removeItemImmediate(itemIndex);
          }

          _pendingNotifications.add(evictedWidget);
          _sortPending();

          _processPending();
          _checkEmpty();
        }
      });
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
            key: _listKey,
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
      alignment: Alignment(-1.0, alignment),
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
