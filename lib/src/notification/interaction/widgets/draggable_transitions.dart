part of '../../notification.dart';

class DraggableTransitions extends StatefulWidget {
  const DraggableTransitions({
    required this.notification,
    this.hapticFeedbackOnStart = true,
    super.key,
  });

  final NotificationWidget notification;
  final bool hapticFeedbackOnStart;

  @override
  State<DraggableTransitions> createState() => DraggableTransitionsState();
}

class DraggableTransitionsState extends State<DraggableTransitions>
    with SingleTickerProviderStateMixin {
  late Size _screenSize;

  final ValueNotifier<OffsetPair?> _dragOffsetPairNotifier =
      ValueNotifier(null);

  List<SlotDropZone>? _activeReorderZones;

  late final GestureStateMachine _fsm;

  late final AnimationController _snapBackController;
  Animation<Offset>? _snapBackAnimation;
  bool _isSnapBackAnimating = false;

  static final _logger = Logger.get('fnq.Notification.Draggables');

  @override
  void initState() {
    final message = 'Notification${widget.notification.key} '
        'DraggableTransition created State';
    _logger.debugBuffer
      ?..writeAll([
        message,
        'State: $this',
      ])
      ..sink();

    final dragBehavior = widget.notification.dragBehavior ??
        widget.notification.queue.dragBehavior;
    final position = widget.notification.queue.position;
    final escapeThreshold = dragBehavior is ReorderAndRelocate
        ? (dragBehavior as ReorderAndRelocate).escapeThresholdInPixels
        : 80.0;

    _fsm = GestureStateMachine(
      initialBehavior: dragBehavior,
      initialPosition: position,
      escapeThreshold: escapeThreshold,
    );

    _snapBackController = AnimationController(
      vsync: this,
    );

    super.initState();
  }

  @override
  void didChangeDependencies() {
    _logger.debugBuffer
      ?..writeAll([
        'Notification${widget.notification.key} DraggableTransition',
        'State: $this',
      ])
      ..sink();
    _screenSize = MediaQuery.of(context).size;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _logger.debugBuffer
      ?..writeAll([
        'Disposed Notification${widget.notification.key} DraggableTransition.',
        '',
      ])
      ..sink();

    _dragOffsetPairNotifier.dispose();
    _fsm.dispose();
    _snapBackController.dispose();
    super.dispose();
  }

  NotificationGesturePlugin _resolvePlugin(
    final QueueNotificationBehavior behavior,
  ) =>
      switch (behavior) {
        Dismiss() => DismissGesturePlugin(behavior: behavior),
        Relocate() => RelocateGesturePlugin(behavior: behavior),
        Reorder() => ReorderGesturePlugin(behavior: behavior),
        ReorderAndRelocate() => ReorderRelocateGesturePlugin(
            behavior: behavior,
          ),
        final Snooze behavior => SnoozeGesturePlugin(behavior: behavior),
        final Pin behavior => PinGesturePlugin(behavior: behavior),
        final Archive behavior => ArchiveGesturePlugin(behavior: behavior),
        final CustomAction behavior => CustomActionGesturePlugin(
            behavior: behavior,
          ),
        Disabled() => throw UnsupportedError('Disabled behavior has no plugin'),
      };

  int stateIndexOfThisItem() {
    final position = widget.notification.queue.position;
    final queueKey =
        FlutterNotificationQueue.coordinator.getWidgetKey(position);
    final queueState = queueKey.currentState;
    return queueState?.indexOf(widget.notification) ?? 0;
  }

  Widget _buildCardChild() => AnimatedBuilder(
        animation: _snapBackController,
        builder: (final context, final child) {
          final offset = _isSnapBackAnimating && _snapBackAnimation != null
              ? _snapBackAnimation!.value
              : Offset.zero;

          return ValueListenableBuilder<GestureState>(
            valueListenable: _fsm,
            builder: (final context, final fsmState, final child) {
              final cursor = fsmState == GestureState.idle
                  ? SystemMouseCursors.grab
                  : SystemMouseCursors.grabbing;

              return MouseRegion(
                cursor: cursor,
                child: Transform.translate(
                  offset: offset,
                  child: widget.notification,
                ),
              );
            },
          );
        },
      );

  void _startSnapBack(final Offset releaseOffset) {
    final originalPosition = _dragStartData?.widgetPosition ?? Offset.zero;
    final finalRelativeOffset = releaseOffset - originalPosition;

    setState(() {
      _isSnapBackAnimating = true;
    });

    final dragBehavior = widget.notification.dragBehavior ??
        widget.notification.queue.dragBehavior;
    final physics = dragBehavior.springPhysics;

    final simulation = SpringSimulation(
      physics.toSpringDescription(),
      1.0,
      0.0,
      0.0,
    );

    _snapBackAnimation = Tween<Offset>(
      begin: finalRelativeOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _snapBackController,
      curve: Curves.linear,
    ),);

    _snapBackController.animateWith(simulation).then((final _) {
      if (mounted) {
        setState(() {
          _isSnapBackAnimating = false;
          _fsm.reset();
        });
      }
    });
  }

  Widget _buildDraggable({
    required final QueueNotificationBehavior behavior,
    required final bool isLongPress,
  }) {
    final plugin = _resolvePlugin(behavior);

    int? originalIndex;

    void onDragStarted() {
      if (_isSnapBackAnimating) {
        _snapBackController.stop();
        _isSnapBackAnimating = false;
      }

      originalIndex = stateIndexOfThisItem();

      final renderBox = context.findRenderObject() as RenderBox?;
      final rect = renderBox != null
          ? (renderBox.localToGlobal(Offset.zero) & renderBox.size)
          : Rect.zero;

      _fsm.lift(
        pointerStart: _dragStartData?.pointerPosition ?? Offset.zero,
        widgetRect: rect,
      );

      if (widget.hapticFeedbackOnStart) {
        HapticFeedback.lightImpact();
      }

      final position = widget.notification.queue.position;
      final queueKey =
          FlutterNotificationQueue.coordinator.getWidgetKey(position);
      queueKey.currentState?.setActiveDragGroup(
        widget.notification.resolvedGroupKey,
      );

      plugin.onDragStart(this);
    }

    void onDragUpdate(final DragUpdateDetails details) {
      _fsm.update(
        delta: details.delta,
        globalPosition: details.globalPosition,
      );
      plugin.onDragUpdate(this, details);
    }

    void onDragEnd(final DraggableDetails details) {
      _fsm.settle();
      plugin.onDragEnd(this, details);

      final currentQueuePosition = widget.notification.queue.position;
      final isExiting =
          widget.notification.key.currentState?.animationController.status ==
              AnimationStatus.reverse;
      final isRelocated = currentQueuePosition != _fsm.initialPosition;
      final isReordered =
          originalIndex != null && stateIndexOfThisItem() != originalIndex;

      if (!isExiting &&
          !isRelocated &&
          !isReordered &&
          _dragStartData != null) {
        final originalPosition = _dragStartData!.widgetPosition;
        final releaseOffset = details.offset;
        final distance = (releaseOffset - originalPosition).distance;
        if (distance > 1.0) {
          _startSnapBack(releaseOffset);
        } else {
          _fsm.reset();
        }
      } else {
        _fsm.reset();
      }

      final position = widget.notification.queue.position;
      final queueKey =
          FlutterNotificationQueue.coordinator.getWidgetKey(position);
      queueKey.currentState?.setActiveDragGroup(null);
    }

    final feedback = ValueListenableBuilder(
      valueListenable: _dragOffsetPairNotifier,
      builder: (final context, final offsetPair, final child) => MouseRegion(
        cursor: SystemMouseCursors.grabbing,
        child: plugin.buildFeedback(this, offsetPair),
      ),
    );

    final position = widget.notification.queue.position;

    if (isLongPress) {
      final Object data = switch (behavior) {
        Relocate() => position,
        Dismiss() => position.alignment,
        Reorder() => stateIndexOfThisItem(),
        ReorderAndRelocate() => stateIndexOfThisItem(),
        Snooze() => position.alignment,
        Pin() => position.alignment,
        Archive() => position.alignment,
        CustomAction() => position.alignment,
        _ => position,
      };

      return LongPressDraggable<Object>(
        data: data,
        axis: null,
        onDragStarted: onDragStarted,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
        maxSimultaneousDrags: 1,
        hapticFeedbackOnStart: widget.hapticFeedbackOnStart,
        hitTestBehavior: HitTestBehavior.deferToChild,
        childWhenDragging: behavior is Reorder || behavior is ReorderAndRelocate
            ? _ReorderPlaceholder(
                child:
                    _buildDummyGhost(_dragStartData?.widgetSize ?? Size.zero),
              )
            : const SizedBox.shrink(),
        feedback: feedback,
        child: draggable(),
      );
    }

    final Object data = switch (behavior) {
      Relocate() => position,
      Dismiss() => position.alignment,
      Reorder() => stateIndexOfThisItem(),
      ReorderAndRelocate() => stateIndexOfThisItem(),
      Snooze() => position.alignment,
      Pin() => position.alignment,
      Archive() => position.alignment,
      CustomAction() => position.alignment,
      _ => position,
    };

    return Draggable<Object>(
      data: data,
      axis: null,
      onDragStarted: onDragStarted,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      maxSimultaneousDrags: 1,
      hitTestBehavior: HitTestBehavior.deferToChild,
      childWhenDragging: behavior is Reorder || behavior is ReorderAndRelocate
          ? _ReorderPlaceholder(
              child: _buildDummyGhost(_dragStartData?.widgetSize ?? Size.zero),
            )
          : const SizedBox.shrink(),
      feedback: feedback,
      child: _buildCardChild(),
    );
  }

  // Derives the active drop zones based on the interaction behavior.
  List<DropZone> _getZones(
    final QueueNotificationBehavior behavior,
    final QueuePosition position,
  ) {
    if (behavior is Dismiss) {
      return _edgesFromDismissZone(behavior.zones, position);
    } else if (behavior is Snooze) {
      return _edgesFromDismissZone(DismissZone.sideEdges, position);
    } else if (behavior is Pin) {
      return _edgesFromDismissZone(DismissZone.sideEdges, position);
    } else if (behavior is Archive) {
      return _edgesFromDismissZone(DismissZone.sideEdges, position);
    } else if (behavior is CustomAction) {
      return _edgesFromDismissZone(DismissZone.sideEdges, position);
    } else if (behavior is Relocate) {
      return _zonesFromPositions(behavior.positions, position);
    } else if (behavior is ReorderAndRelocate) {
      return _zonesFromPositions(behavior.positions, position);
    }
    return [];
  }

  bool _passedThreshold(
    final Offset? globalOffset,
    final int thresholdInPixels,
    final List<DropZone> zones,
  ) {
    if (globalOffset == null) {
      return false;
    }

    for (final zone in zones) {
      if (zone.isHit(globalOffset, _screenSize, thresholdInPixels.toDouble())) {
        return true;
      }
    }
    return false;
  }

  double _nearestZoneProgress(
    final Offset? pointer,
    final List<DropZone> zones,
  ) {
    if (pointer == null) {
      return 0.0;
    }
    var best = 0.0;
    for (final zone in zones) {
      if (zone is SlotDropZone) {
        final p = zone.calculateProgress(pointer, 1.0 / 120.0);
        if (p > best) {
          best = p;
        }
      }
    }
    return best;
  }

  final OverlayPortalController _overlayPortalController =
      OverlayPortalController();

  @override
  Widget build(final BuildContext context) => Listener(
        onPointerDown: (final event) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            _dragStartData = _DragStartData(
              widgetPosition: renderBox.localToGlobal(Offset.zero),
              pointerPosition: event.position,
              widgetSize: renderBox.size,
            );
          }
        },
        child: longPressWidget(),
      );

  _DragStartData? _dragStartData;
  int? _activeZoneIndex;

  int? _nearestZoneIndexWithHysteresis(
    final Offset? pointer,
    final List<SlotDropZone> zones,
  ) {
    if (pointer == null || zones.isEmpty) {
      return null;
    }
    var minDistance = double.infinity;
    int? bestIndex;
    const double gravityWell = 40.0;

    for (var i = 0; i < zones.length; i++) {
      final anchor = zones[i].anchor;
      if (anchor == null) {
        continue;
      }
      double distance = (pointer - anchor).distance;
      if (i == _activeZoneIndex) {
        distance -= gravityWell;
      }
      if (distance < minDistance) {
        minDistance = distance;
        bestIndex = i;
      }
    }

    _activeZoneIndex = bestIndex;
    return bestIndex;
  }

  Widget longPressWidget() =>
      switch (widget.notification.longPressDragBehavior ??
          widget.notification.queue.longPressDragBehavior) {
        Disabled() => draggable(),
        final behavior =>
          _buildDraggable(behavior: behavior, isLongPress: true),
      };

  Widget draggable() => switch (widget.notification.dragBehavior ??
          widget.notification.queue.dragBehavior) {
        Disabled() => _buildCardChild(),
        final behavior =>
          _buildDraggable(behavior: behavior, isLongPress: false),
      };

  Widget _buildDummyGhost(final Size size) => Container(
        width: size.width > 0 ? size.width : null,
        height: size.height > 0 ? size.height : null,
        decoration: BoxDecoration(
          color: widget.notification.backgroundColor ??
              const Color(0xFF2B2C50), // Fallback to a typical dark card color
          borderRadius: BorderRadius.circular(14),
        ),
      );
}
