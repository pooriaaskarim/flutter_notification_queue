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
      _activeReorderZones = _zonesFromSlots(itemCount, currentIndex);
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
          final nearestIndex = _nearestZoneIndex(pointer, zones);
          if (nearestIndex != null) {
            FlutterNotificationQueue.coordinator
                .reorder(widget.notification, nearestIndex);
          }
        }
      }
      _activeReorderZones = null;
      _dragOffsetPairNotifier.value = null;
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

        return OverlayPortal(
          controller: _overlayPortalController,
          overlayChildBuilder: (final context) => LayoutBuilder(
            builder: (final context, final constraints) => _ReorderTargets(
              draggedIndex: currentIndex,
              zones: zones,
              itemKeys: queueState?.itemGlobalKeys ?? [],
              passedThreshold: passedThreshold,
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
