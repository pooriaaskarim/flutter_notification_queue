part of '../../notification.dart';

extension _RelocateBehaviorExtension on DraggableTransitionsState {
  Widget _buildRelocateDraggable({required final bool isLongPress}) {
    final position = widget.notification.queue.position;
    final behavior = (isLongPress
        ? widget.notification.queue.longPressDragBehavior
        : widget.notification.queue.dragBehavior) as Relocate;

    void onDragStarted() {
      FlutterNotificationQueue.coordinator.bringToFront(position);
      widget.notification.key.currentState?.ditchDismissTimer();
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
        final zones = _getZones(behavior, position);
        final hitZone = zones
            .cast<PositionDropZone>()
            .where(
              (final z) => z.isHit(
                pointer,
                _screenSize,
                behavior.thresholdInPixels.toDouble(),
              ),
            )
            .firstOrNull;
        if (hitZone != null) {
          FlutterNotificationQueue.coordinator
              .relocate(widget.notification, hitZone.position);
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
            builder: (final context, final constraints) => _RelocationTargets(
              targets: behavior.positions,
              currentPosition: position,
              screenSize: constraints.biggest,
              pointerPositionNotifier: _dragOffsetPairNotifier,
              threshold: behavior.thresholdInPixels.toDouble(),
            ),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeOut,
            opacity: passedThreshold ? 0.3 : 1.0,
            child: widget.notification,
          ),
        );
      },
    );

    if (isLongPress) {
      return LongPressDraggable<Object>(
        data: position,
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
      data: position,
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
