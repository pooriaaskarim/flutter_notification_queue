part of 'notification_queue.dart';

class QueueWidget extends StatefulWidget {
  const QueueWidget({
    required this.queue,
    this.isEmbeddedInLayout = false,
    super.key,
  });

  final NotificationQueue queue;
  final bool isEmbeddedInLayout;

  @override
  State<QueueWidget> createState() => QueueWidgetState();
}

class QueueWidgetState extends State<QueueWidget>
    with TickerProviderStateMixin {
  final _pendingNotifications = Queue<NotificationWidget>();
  final List<_NotificationItemState> _items = [];
  final Set<String> _expandedGroups = {};

  List<_NotificationItemState> get _visibleItems =>
      _items.where(_isItemVisible).toList();

  /// Key attached to the inner Column to measure the queue's exact visual
  /// bounds.
  final GlobalKey _listKey = GlobalKey();

  int? _draggedTargetIndex;
  int? _draggedItemOriginIndex;

  void startDragReorder(final String itemId, final int originIndex) {
    setState(() {
      _draggedItemOriginIndex = originIndex;
      _draggedTargetIndex = originIndex;
    });
  }

  void updateDragTarget(final int targetIndex) {
    if (_draggedTargetIndex != targetIndex) {
      setState(() {
        _draggedTargetIndex = targetIndex;
      });
    }
  }

  void clearDragTarget() {
    if (_draggedTargetIndex != null) {
      setState(() {
        _draggedTargetIndex = null;
      });
    }
  }

  void endDragReorder() {
    setState(() {
      _draggedItemOriginIndex = null;
      _draggedTargetIndex = null;
    });
  }

  double _getItemHeight(final int visibleIndex) {
    final visible = _visibleItems;
    if (visibleIndex < 0 || visibleIndex >= visible.length) {
      return 0.0;
    }
    final key = visible[visibleIndex].globalKey;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.size.height;
    }
    return 80.0;
  }

  double getTranslationY(final int i) {
    final origin = _draggedItemOriginIndex;
    final target = _draggedTargetIndex;
    if (origin == null || target == null || origin == target) {
      return 0.0;
    }

    final spacing = widget.queue.spacing;
    final directionMultiplier =
        widget.queue.verticalDirection == VerticalDirection.down ? 1.0 : -1.0;

    if (target < origin) {
      if (i >= target && i < origin) {
        final draggedHeight = _getItemHeight(origin) + spacing;
        return draggedHeight * directionMultiplier;
      }
      if (i == origin) {
        double totalOffset = 0.0;
        for (int k = target; k < origin; k++) {
          totalOffset += _getItemHeight(k) + spacing;
        }
        return -totalOffset * directionMultiplier;
      }
    } else if (target > origin) {
      if (i > origin && i <= target) {
        final draggedHeight = _getItemHeight(origin) + spacing;
        return -draggedHeight * directionMultiplier;
      }
      if (i == origin) {
        double totalOffset = 0.0;
        for (int k = origin + 1; k <= target; k++) {
          totalOffset += _getItemHeight(k) + spacing;
        }
        return totalOffset * directionMultiplier;
      }
    }
    return 0.0;
  }

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

  bool _isItemVisible(final _NotificationItemState item) {
    if (item.status == _ItemStatus.exiting) {
      return true;
    }
    if (!widget.queue.groupingBehavior.enabled) {
      return true;
    }
    final key = item.widget.resolvedGroupKey;
    final activeGroupItems = _items
        .where((final i) =>
            i.widget.resolvedGroupKey == key &&
                i.status != _ItemStatus.exiting,)
        .toList();
    if (activeGroupItems.length <
        widget.queue.groupingBehavior.maxBeforeGrouping) {
      return true;
    }
    if (_expandedGroups.contains(key)) {
      return true;
    }
    return item == activeGroupItems.last;
  }

  void dismiss(final NotificationWidget notification) {
    final key = notification.resolvedGroupKey;
    final isGrouped = widget.queue.groupingBehavior.enabled;
    final isCollapsed = !_expandedGroups.contains(key);

    if (isGrouped && isCollapsed) {
      final groupItems = _items
          .where((final item) => item.widget.resolvedGroupKey == key)
          .toList();

      if (groupItems.length >=
          widget.queue.groupingBehavior.maxBeforeGrouping) {
        for (final item in groupItems) {
          _animateExit(item);
        }
        return;
      }
    }

    final index = _indexOf(notification.id);
    if (index != -1) {
      _animateExit(_items[index]);
    } else {
      _pendingNotifications.removeWhere((final n) => n.id == notification.id);
      _checkEmpty();
    }
  }

  bool remove(final NotificationWidget notification) {
    final key = notification.resolvedGroupKey;
    final isGrouped = widget.queue.groupingBehavior.enabled;
    final isCollapsed = !_expandedGroups.contains(key);

    if (isGrouped && isCollapsed) {
      final groupItems = _items
          .where((final item) => item.widget.resolvedGroupKey == key)
          .toList();
      if (groupItems.length >=
          widget.queue.groupingBehavior.maxBeforeGrouping) {
        bool anyRemoved = false;
        for (final item in groupItems) {
          final idx = _items.indexOf(item);
          if (idx != -1) {
            _removeItemImmediate(idx);
            anyRemoved = true;
          }
        }
        if (anyRemoved) {
          _processPending();
          _checkEmpty();
        }
        return anyRemoved;
      }
    }

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
    final key = notification.resolvedGroupKey;
    final isGrouped = widget.queue.groupingBehavior.enabled;
    final isCollapsed = !_expandedGroups.contains(key);

    setState(() {
      if (isGrouped && isCollapsed) {
        final groupItems = _items
            .where((final item) => item.widget.resolvedGroupKey == key)
            .toList();

        for (final item in groupItems) {
          _items.remove(item);
        }

        int absoluteInsertIndex = 0;
        final visibleItemsRemaining = _items.where(_isItemVisible).toList();
        if (targetIndex > 0 && targetIndex - 1 < visibleItemsRemaining.length) {
          final anchorItem = visibleItemsRemaining[targetIndex - 1];
          absoluteInsertIndex = _items.indexOf(anchorItem) + 1;
        } else if (targetIndex >= visibleItemsRemaining.length) {
          absoluteInsertIndex = _items.length;
        }

        _items.insertAll(absoluteInsertIndex, groupItems);
      } else {
        final currentIndex = _indexOf(notification.id);
        if (currentIndex == -1) {
          return;
        }
        final item = _items.removeAt(currentIndex);

        int absoluteInsertIndex = 0;
        final visibleItemsRemaining = _items.where(_isItemVisible).toList();
        if (targetIndex > 0 && targetIndex - 1 < visibleItemsRemaining.length) {
          final anchorItem = visibleItemsRemaining[targetIndex - 1];
          absoluteInsertIndex = _items.indexOf(anchorItem) + 1;
        } else if (targetIndex >= visibleItemsRemaining.length) {
          absoluteInsertIndex = _items.length;
        }

        _items.insert(absoluteInsertIndex, item);
      }
    });
  }

  /// The number of currently active (non-pending) notifications.
  int get itemCount => _visibleItems.length;

  /// The list of currently active notifications in this queue.
  List<NotificationWidget> get activeNotifications =>
      _items.map((final item) => item.widget).toList();

  /// The active-list index of [notification], or -1 if not found.
  int indexOf(final NotificationWidget notification) => _visibleItems
      .indexWhere((final item) => item.widget.id == notification.id);

  /// The [GlobalKey]s of active notification widgets, in stack order.
  ///
  /// Used by the reorder feedback layer to query each notification's
  /// [RenderBox] position for slot anchor computation.
  List<GlobalKey> get itemGlobalKeys =>
      _visibleItems.map((final item) => item.globalKey).toList();

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
    final content = ConstrainedBox(
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
    );

    if (widget.isEmbeddedInLayout) {
      return content;
    }

    return SafeArea(
      child: Container(
        alignment: widget.queue.position.alignment,
        margin: widget.queue.margin,
        child: content,
      ),
    );
  }

  Widget _buildItem(final _NotificationItemState item) {
    if (!_isItemVisible(item)) {
      return const SizedBox.shrink();
    }

    final alignment =
        widget.queue.verticalDirection == VerticalDirection.down ? -1.0 : 1.0;

    final visible = _visibleItems;
    final isLast = item == visible.last;
    final spacing = isLast ? 0.0 : widget.queue.spacing;

    final visibleIndex = visible.indexOf(item);
    final translationY = getTranslationY(visibleIndex);

    Widget itemWidget = widget.queue.transition.build(
      context,
      item.controller,
      widget.queue.position,
      KeyedSubtree(
        key: item.globalKey,
        child: DraggableTransitions(
          notification: item.widget,
        ),
      ),
    );

    if (widget.queue.groupingBehavior.enabled) {
      final key = item.widget.resolvedGroupKey;
      final groupItems = _items
          .where((final i) =>
              i.widget.resolvedGroupKey == key &&
              i.status != _ItemStatus.exiting,)
          .toList();
      if (groupItems.length >=
          widget.queue.groupingBehavior.maxBeforeGrouping) {
        final isExpanded = _expandedGroups.contains(key);
        if (item == groupItems.last) {
          itemWidget = _GroupBundleWidget(
            notification: item.widget,
            count: groupItems.length,
            isExpanded: isExpanded,
            onToggle: () {
              setState(() {
                if (isExpanded) {
                  _expandedGroups.remove(key);
                } else {
                  _expandedGroups.add(key);
                }
              });
            },
            style: widget.queue.style,
            verticalDirection: widget.queue.verticalDirection,
            child: itemWidget,
          );
        }
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, translationY, 0),
      child: SizeTransition(
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
            child: itemWidget,
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

class _GroupBundleWidget extends StatelessWidget {
  const _GroupBundleWidget({
    required this.child,
    required this.count,
    required this.isExpanded,
    required this.onToggle,
    required this.style,
    required this.verticalDirection,
    required this.notification,
  });

  final Widget child;
  final int count;
  final bool isExpanded;
  final VoidCallback onToggle;
  final QueueStyle style;
  final VerticalDirection verticalDirection;
  final NotificationWidget notification;

  @override
  Widget build(final BuildContext context) {
    if (isExpanded) {
      return Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            bottom: -10,
            child: _buildTogglePill(context),
          ),
        ],
      );
    }

    final directionMultiplier =
        verticalDirection == VerticalDirection.down ? 1.0 : -1.0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: verticalDirection == VerticalDirection.down ? 12.0 : 0,
        top: verticalDirection == VerticalDirection.up ? 12.0 : 0,
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          if (count > 2)
            Positioned(
              left: 16,
              right: 16,
              top: 12 * directionMultiplier,
              bottom: -12 * directionMultiplier,
              child: _buildLayer(context, 0.90, 0.4),
            ),
          if (count > 1)
            Positioned(
              left: 8,
              right: 8,
              top: 6 * directionMultiplier,
              bottom: -6 * directionMultiplier,
              child: _buildLayer(context, 0.95, 0.7),
            ),
          child,
          Positioned(
            bottom: -10,
            child: _buildTogglePill(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLayer(
    final BuildContext context,
    final double scale,
    final double opacity,
  ) {
    final resolvedTheme =
        NotificationTheme.resolveWith(context, style, notification);
    final cardColor = resolvedTheme.backgroundColor;

    final container = Material(
      shape: resolvedTheme.shape,
      color: cardColor.withValues(alpha: resolvedTheme.opacity * opacity),
      elevation: resolvedTheme.elevation * opacity,
      type: MaterialType.canvas,
      child: const SizedBox.expand(),
    );

    return Transform.scale(
      scaleX: scale,
      scaleY: 1.0,
      alignment: Alignment.topCenter,
      child: container,
    );
  }

  Widget _buildTogglePill(final BuildContext context) {
    final resolvedTheme =
        NotificationTheme.resolveWith(context, style, notification);
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: resolvedTheme.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isExpanded ? 'Collapse' : '+$count More',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: resolvedTheme.foregroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 14,
                color: resolvedTheme.foregroundColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
