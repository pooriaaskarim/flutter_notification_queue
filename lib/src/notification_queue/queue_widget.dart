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

  /// The resolved group key of the group whose representative is currently
  /// being dragged. While non-null, the item immediately behind the
  /// representative ("the peek card") is also rendered as visible so the
  /// user can see the next notification surface from beneath the lifted card.
  String? _activeDragGroupKey;

  /// Called by the gesture plugins at drag-start on a group representative.
  void setActiveDragGroup(final String? key) {
    if (_activeDragGroupKey == key) {
      return;
    }
    setState(() => _activeDragGroupKey = key);
    if (key != null) {
      _syncGroupTimers(key);
    }
  }

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

  /// Returns true when [item] is the "peek card" — the card rendered
  /// semi-transparently behind the dragged representative.
  bool _isPeekItem(
    final _NotificationItemState item,
    final String groupKey,
    final List<_NotificationItemState> activeGroupItems,
  ) {
    if (_activeDragGroupKey != groupKey) {
      return false;
    }
    final rep = _groupRepresentative(activeGroupItems);
    final repIdx = activeGroupItems.indexOf(rep);
    final peekIdx = widget.queue.verticalDirection == VerticalDirection.up
        ? repIdx + 1
        : repIdx - 1;
    if (peekIdx < 0 || peekIdx >= activeGroupItems.length) {
      return false;
    }
    return item == activeGroupItems[peekIdx];
  }

  /// Returns the notification that acts as the visible representative for
  /// a collapsed group. For top-anchored queues the newest card
  /// (`last`) is shown; for bottom-anchored queues the oldest (`first`)
  /// is shown because it sits closest to the screen edge the user reads.
  _NotificationItemState _groupRepresentative(
    final List<_NotificationItemState> groupItems,
  ) =>
      widget.queue.verticalDirection == VerticalDirection.up
          ? groupItems.first
          : groupItems.last;

  bool _isItemVisible(final _NotificationItemState item) {
    if (item.status == _ItemStatus.exiting) {
      return true;
    }
    if (!widget.queue.groupingBehavior.enabled) {
      return true;
    }
    final key = item.widget.resolvedGroupKey;
    final activeGroupItems = _items
        .where(
          (final i) =>
              i.widget.resolvedGroupKey == key &&
              i.status != _ItemStatus.exiting,
        )
        .toList();
    if (activeGroupItems.length <
        widget.queue.groupingBehavior.maxBeforeGrouping) {
      return true;
    }
    if (_expandedGroups.contains(key)) {
      return true;
    }
    // Peek card: while the representative is being dragged, also show the
    // card directly behind it so the user sees what's "underneath the pile".
    if (_activeDragGroupKey == key) {
      final rep = _groupRepresentative(activeGroupItems);
      final repIdx = activeGroupItems.indexOf(rep);
      // The item immediately behind the representative in insertion order.
      final peekIdx = widget.queue.verticalDirection == VerticalDirection.up
          ? repIdx + 1
          : repIdx - 1;
      if (peekIdx >= 0 && peekIdx < activeGroupItems.length) {
        if (item == activeGroupItems[peekIdx]) {
          return true;
        }
      }
    }
    return item == _groupRepresentative(activeGroupItems);
  }

  void dismiss(
    final NotificationWidget notification, {
    final DismissReason reason = DismissReason.programmatic,
  }) {
    final index = _indexOf(notification.id);
    if (index != -1) {
      _animateExit(_items[index], reason: reason);
    } else {
      _pendingNotifications.removeWhere(
        (final n) => n.id == notification.id,
      );
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
      _pendingNotifications.removeWhere(
        (final n) => n.id == notification.id,
      );
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

  /// Dismisses every notification that shares [groupKey] with an animated
  /// exit, regardless of collapsed/expanded state.
  ///
  /// This is the correct way to bulk-remove a bundle. Individual
  /// [dismiss] calls only ever remove a single card.
  void dismissGroup(
    final String groupKey, {
    final DismissReason reason = DismissReason.programmatic,
  }) {
    final groupItems = _items
        .where((final i) => i.widget.resolvedGroupKey == groupKey)
        .toList();
    for (final item in groupItems) {
      _animateExit(item, reason: reason);
    }
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

  void _animateExit(
    final _NotificationItemState item, {
    final DismissReason reason = DismissReason.timeout,
  }) {
    if (item.status == _ItemStatus.exiting) {
      return;
    }

    final groupKey = item.widget.resolvedGroupKey;

    // ── Collapsed-group representative: instant content swap ──────────────
    // When the visible representative of a *collapsed* group is dismissed,
    // the height slot must NOT animate — doing so causes either:
    //   • a disappear-then-reappear flash
    //     (no setState before controller.reverse)
    //   • a double-card artefact
    //     (setState before controller.reverse)
    // Both stem from two independent SizeTransition children sharing one
    // logical slot. The fix: remove the departing card immediately inside the
    // same setState that reveals the new representative, so the column sees
    // one clean swap in a single frame. The swipe gesture already delivered
    // the exit feedback; no height animation is needed here.
    if (_isCollapsedGroupRepresentative(item, groupKey)) {
      setState(() {
        item.status = _ItemStatus.exiting;
        final index = _items.indexOf(item);
        if (index != -1) {
          _items.removeAt(index);
          item.controller.dispose();
        }
        // Clear the drag peek — the representative is gone.
        if (_activeDragGroupKey == groupKey) {
          _activeDragGroupKey = null;
        }
        // Stamp a fresh entrance key on the new representative so its
        // micro-animation re-triggers (UX-02).
        final activeItems = _items.where(
          (final i) =>
              i.widget.resolvedGroupKey == groupKey &&
              i.status != _ItemStatus.exiting,
        );
        if (activeItems.isNotEmpty) {
          _groupRepresentative(activeItems.toList()).entranceKey = UniqueKey();
        }
      });
      _syncGroupTimers(groupKey);
      _pruneExpandedGroup(groupKey);
      _processPending();
      _checkEmpty();
      return;
    }

    // ── All other cases: normal size-collapse animation ───────────────────
    item.status = _ItemStatus.exiting;
    _syncGroupTimers(groupKey);
    item.controller.reverse().then((final _) {
      if (mounted) {
        _removeItemImmediate(_items.indexOf(item));
        _pruneExpandedGroup(groupKey);
        _processPending();
        _checkEmpty();
      }
    });
  }

  /// Returns true when [item] is currently the sole visible card of a
  /// collapsed group that still has enough members to remain a bundle after
  /// this item is removed.
  ///
  /// This is the only situation where the height slot should NOT animate:
  /// the next representative immediately fills the same slot.
  bool _isCollapsedGroupRepresentative(
    final _NotificationItemState item,
    final String groupKey,
  ) {
    if (!widget.queue.groupingBehavior.enabled) {
      return false;
    }
    if (_expandedGroups.contains(groupKey)) {
      return false;
    }
    final activeItems = _items
        .where(
          (final i) =>
              i.widget.resolvedGroupKey == groupKey &&
              i.status != _ItemStatus.exiting,
        )
        .toList();
    // Must still form a group after removal (length - 1 >= threshold).
    final remainingCount = activeItems.length - 1;
    if (remainingCount < widget.queue.groupingBehavior.maxBeforeGrouping) {
      return false;
    }
    return item == _groupRepresentative(activeItems);
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

  /// Removes [groupKey] from [_expandedGroups] if no item in [_items]
  /// still belongs to that group. Must be called *after* the departing
  /// item has been removed from [_items].
  void _pruneExpandedGroup(final String groupKey) {
    if (_expandedGroups.contains(groupKey)) {
      final stillExists = _items.any(
        (final i) => i.widget.resolvedGroupKey == groupKey,
      );
      if (!stillExists) {
        setState(() {
          _expandedGroups.remove(groupKey);
        });
      }
    }
  }

  /// Synchronises dismiss timers for every member of [groupKey].
  ///
  /// Called at the two precise moments when group visibility actually changes:
  /// - When the bundle is toggled (expand ↔ collapse).
  /// - When the visible representative exits (the next card surfaces).
  ///
  /// This is O(n) and called at most once per user interaction — never on
  /// every build frame.
  void _syncGroupTimers(final String groupKey) {
    if (!widget.queue.groupingBehavior.enabled) {
      return;
    }
    for (final item in _items) {
      if (item.widget.resolvedGroupKey != groupKey) {
        continue;
      }
      final notifState = item.widget.key.currentState;
      if (notifState == null) {
        continue;
      }
      if (_isItemVisible(item)) {
        if (notifState.dismissTimer == null) {
          notifState.initDismissTimer();
        }
      } else {
        notifState.ditchDismissTimer();
      }
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
    final isVisible = _isItemVisible(item);

    if (!isVisible) {
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
          .where(
            (final i) =>
                i.widget.resolvedGroupKey == key &&
                i.status != _ItemStatus.exiting,
          )
          .toList();
      if (groupItems.length >=
          widget.queue.groupingBehavior.maxBeforeGrouping) {
        final isExpanded = _expandedGroups.contains(key);
        final representative = _groupRepresentative(groupItems);

        // UX-01: Peek card — rendered dimmed/scaled behind the dragged rep.
        if (_isPeekItem(item, key, groupItems)) {
          itemWidget = IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              builder: (final ctx, final t, final child) => Opacity(
                opacity: 0.55 * t,
                child: Transform.scale(
                  scale: 0.94 + 0.06 * t,
                  alignment: Alignment.topCenter,
                  child: child,
                ),
              ),
              child: itemWidget,
            ),
          );
        }

        if (item == representative) {
          // UX-02: Entrance micro-animation — replays whenever entranceKey
          // changes (i.e. after an instant-swap).
          itemWidget = TweenAnimationBuilder<double>(
            key: item.entranceKey,
            tween: Tween(begin: 0.96, end: 1.0),
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOut,
            builder: (final ctx, final scale, final child) =>
                Transform.scale(scale: scale, child: child),
            child: itemWidget,
          );

          // Hidden items = all group members except the representative,
          // sorted so the "next in line" is first.
          final hiddenItems = groupItems
              .where((final i) => i != representative)
              .toList();

          itemWidget = _GroupBundleWidget(
            notification: item.widget,
            count: groupItems.length,
            isExpanded: isExpanded,
            hiddenItems: hiddenItems,
            onToggle: () {
              setState(() {
                if (isExpanded) {
                  _expandedGroups.remove(key);
                } else {
                  _expandedGroups.add(key);
                }
              });
              // Sync timers after toggling so newly-hidden members stop their
              // countdown and newly-visible members resume it.
              _syncGroupTimers(key);
              FlutterNotificationQueue.coordinator.emitGroupToggled(
                groupKey: key,
                position: widget.queue.position,
                expanded: !isExpanded,
                count: groupItems.length,
              );
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

  /// Regenerated on each instant-swap so the representative's
  /// TweenAnimationBuilder re-triggers its entrance micro-animation.
  Key entranceKey = UniqueKey();
}

class _GroupBundleWidget extends StatelessWidget {
  const _GroupBundleWidget({
    required this.child,
    required this.count,
    required this.isExpanded,
    required this.hiddenItems,
    required this.onToggle,
    required this.style,
    required this.verticalDirection,
    required this.notification,
  });

  final Widget child;
  final int count;
  final bool isExpanded;
  /// All group members that are NOT the current representative,
  /// ordered so `hiddenItems.first` is next in line to surface.
  final List<_NotificationItemState> hiddenItems;
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
    final fg = resolvedTheme.foregroundColor;

    // UX-03: next-in-line preview — title + truncated message.
    final nextItem = hiddenItems.isNotEmpty ? hiddenItems.first : null;
    final nextTitle = nextItem?.widget.title;
    final nextMessage = nextItem?.widget.message;
    final hiddenCount = count - 1; // excludes the visible representative

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        onLongPress: onToggle, // accessibility: long-press also toggles
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: resolvedTheme.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Sender + preview (collapsed only) ──
              if (!isExpanded && nextTitle != null) ...[
                Text(
                  nextTitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (nextMessage != null) ...[
                  Text(
                    '  ·  ',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: fg.withValues(alpha: 0.5)),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      nextMessage,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: fg.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(width: 6),
              ],
              // ── Count badge ──
              if (!isExpanded)
                Text(
                  '+$hiddenCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (isExpanded)
                Text(
                  'Collapse',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 14,
                color: fg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
