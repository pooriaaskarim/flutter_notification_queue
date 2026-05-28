part of '../../notification.dart';

extension _DismissBehaviorExtension on DraggableTransitionsState {
  Widget _buildDismissDraggable({required final bool isLongPress}) {
    final position = widget.notification.queue.position;
    final behavior = (isLongPress
        ? widget.notification.queue.longPressDragBehavior
        : widget.notification.queue.dragBehavior) as Dismiss;

    void onDragStarted() {
      FlutterNotificationQueue.coordinator.bringToFront(position);
      widget.notification.key.currentState?.ditchDismissTimer();
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
        final zones = _getZones(behavior, position);
        final isHit = zones.any(
          (final z) => z.isHit(
            pointer,
            _screenSize,
            behavior.thresholdInPixels.toDouble(),
          ),
        );
        if (isHit) {
          widget.notification.key.currentState?.dismiss();
        }
      }
      _dragOffsetPairNotifier.value = null;
      widget.notification.key.currentState?.initDismissTimer();
      _overlayPortalController.hide();
    }

    final feedback = ValueListenableBuilder(
      valueListenable: _dragOffsetPairNotifier,
      builder: (final context, final offsetPair, final child) {
        final pointer = offsetPair?.global;
        final zones = _getZones(behavior, position);
        final passedThreshold = _passedThreshold(
          pointer,
          behavior.thresholdInPixels,
          zones,
        );

        return OverlayPortal(
          controller: _overlayPortalController,
          overlayChildBuilder: (final context) => LayoutBuilder(
            builder: (final context, final constraints) => _DismissalTargets(
              screenSize: constraints.biggest,
              threshold: behavior.thresholdInPixels.toDouble(),
              zones: zones.cast<EdgeDropZone>(),
              pointerPositionNotifier: _dragOffsetPairNotifier,
            ),
          ),
          child: _DismissFeedbackOverlay(
            passedThreshold: passedThreshold,
            dragOffset: pointer,
            thresholdInPixels: behavior.thresholdInPixels,
            screenSize: _screenSize,
            startData: _dragStartData,
            zones: zones.cast<EdgeDropZone>(),
            child: widget.notification,
          ),
        );
      },
    );

    if (isLongPress) {
      return LongPressDraggable<Object>(
        data: position.alignment,
        axis: null,
        onDragStarted: onDragStarted,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
        maxSimultaneousDrags: 1,
        hapticFeedbackOnStart: widget.hapticFeedbackOnStart,
        hitTestBehavior: HitTestBehavior.deferToChild,
        childWhenDragging: const SizedBox.shrink(),
        feedback: feedback,
        child: draggable(),
      );
    }

    return Draggable<Object>(
      data: position.alignment,
      axis: null,
      onDragStarted: onDragStarted,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      maxSimultaneousDrags: 1,
      hitTestBehavior: HitTestBehavior.deferToChild,
      childWhenDragging: const SizedBox.shrink(),
      feedback: feedback,
      child: widget.notification,
    );
  }
}
