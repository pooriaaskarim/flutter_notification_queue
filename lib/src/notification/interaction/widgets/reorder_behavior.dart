part of '../../notification.dart';

extension _ReorderBehaviorExtension on DraggableTransitionsState {
  Widget _buildReorderDraggable({required final bool isLongPress}) {
    final position = widget.notification.queue.position;
    final behavior = isLongPress
        ? widget.notification.queue.longPressDragBehavior as Reorder
        : widget.notification.queue.dragBehavior as Reorder;
    final queueKey =
        FlutterNotificationQueue.coordinator.getWidgetKey(position);
    final queueState = queueKey.currentState;
    final itemCount = queueState?.itemCount ?? 1;
    final currentIndex = queueState?.indexOf(widget.notification) ?? 0;

    void onDragStarted() {
      FlutterNotificationQueue.coordinator.bringToFront(position);
      widget.notification.key.currentState?.ditchDismissTimer();
      _activeZoneIndex = null;
      _activeReorderZones = _zonesFromSlots(itemCount, currentIndex);
      _dragOffsetPairNotifier.value = OffsetPair(
        local: Offset.zero,
        global: _dragStartData?.pointerPosition ?? Offset.zero,
      );
      _overlayPortalController.show();
    }

    void onDragUpdate(final DragUpdateDetails details) {
      _dragOffsetPairNotifier.value = OffsetPair(
        local: details.delta,
        global: details.globalPosition,
      );
    }

    void onDragEnd(final DraggableDetails details) {
      final pointer = _dragOffsetPairNotifier.value?.global;
      if (pointer != null) {
        final zones = _activeReorderZones ?? [];
        final passedThreshold = _passedThreshold(
          pointer,
          behavior.thresholdInPixels,
          zones,
        );
        if (passedThreshold) {
          final nearestZoneIdx =
              _nearestZoneIndexWithHysteresis(pointer, zones);
          if (nearestZoneIdx != null) {
            FlutterNotificationQueue.coordinator.reorder(
              widget.notification,
              zones[nearestZoneIdx].targetIndex,
            );
          }
        }
      }
      _activeReorderZones = null;
      _dragOffsetPairNotifier.value = null;
      _activeZoneIndex = null;
      widget.notification.key.currentState?.initDismissTimer();
      _overlayPortalController.hide();
    }

    final feedback = ValueListenableBuilder(
      valueListenable: _dragOffsetPairNotifier,
      builder: (final context, final offsetPair, final child) {
        final pointer = offsetPair?.global;
        final zones = _activeReorderZones ?? [];
        final passedThreshold = _passedThreshold(
          pointer,
          behavior.thresholdInPixels,
          zones,
        );
        final nearestProgress = _nearestZoneProgress(pointer, zones);
        final nearestIndex = _nearestZoneIndexWithHysteresis(pointer, zones);

        return OverlayPortal(
          controller: _overlayPortalController,
          overlayChildBuilder: (final context) => LayoutBuilder(
            builder: (final context, final constraints) => _ReorderTargets(
              draggedIndex: currentIndex,
              zones: zones,
              itemKeys: queueState?.itemGlobalKeys ?? [],
              passedThreshold: passedThreshold,
              nearestIndex: nearestIndex,
              pointerPositionNotifier: _dragOffsetPairNotifier,
              ghostChild: _buildDummyGhost(
                _dragStartData?.widgetSize ?? Size.zero,
              ),
            ),
          ),
          child: _LiftedFeedback(
            passedThreshold: passedThreshold,
            nearestProgress: nearestProgress,
            widgetSize: _dragStartData?.widgetSize ?? Size.zero,
            child: widget.notification,
          ),
        );
      },
    );

    if (isLongPress) {
      return LongPressDraggable<int>(
        data: currentIndex,
        axis: null,
        onDragStarted: onDragStarted,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
        maxSimultaneousDrags: 1,
        hapticFeedbackOnStart: widget.hapticFeedbackOnStart,
        hitTestBehavior: HitTestBehavior.deferToChild,
        childWhenDragging: _ReorderPlaceholder(
          child: _buildDummyGhost(_dragStartData?.widgetSize ?? Size.zero),
        ),
        feedback: feedback,
        child: draggable(),
      );
    }

    return Draggable<int>(
      data: currentIndex,
      axis: null,
      onDragStarted: onDragStarted,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      maxSimultaneousDrags: 1,
      childWhenDragging: _ReorderPlaceholder(
        child: _buildDummyGhost(_dragStartData?.widgetSize ?? Size.zero),
      ),
      feedback: feedback,
      child: widget.notification,
    );
  }
}
