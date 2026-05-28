part of '../../notification.dart';

extension _ReorderRelocateBehaviorExtension on DraggableTransitionsState {
  Widget _buildUnifiedDraggable({required final bool isLongPress}) {
    final position = widget.notification.queue.position;
    final behavior = isLongPress
        ? widget.notification.queue.longPressDragBehavior as ReorderAndRelocate
        : widget.notification.queue.dragBehavior as ReorderAndRelocate;
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
        final reorderZones = _activeReorderZones ?? [];
        final passedThreshold = _passedThreshold(
          pointer,
          behavior.thresholdInPixels,
          reorderZones,
        );

        if (passedThreshold) {
          final nearestZoneIdx =
              _nearestZoneIndexWithHysteresis(pointer, reorderZones);
          if (nearestZoneIdx != null) {
            FlutterNotificationQueue.coordinator.reorder(
              widget.notification,
              reorderZones[nearestZoneIdx].targetIndex,
            );
          }
        } else {
          final relocateZones = _getZones(
            behavior,
            position,
          ).cast<PositionDropZone>();

          final hitPosition = relocateZones
              .where(
                (final z) => z.isHit(
                  pointer,
                  _screenSize,
                  behavior.thresholdInPixels.toDouble(),
                ),
              )
              .firstOrNull;

          if (hitPosition != null) {
            FlutterNotificationQueue.coordinator
                .relocate(widget.notification, hitPosition.position);
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

        bool isEscaped = false;
        if (pointer != null && queueState != null) {
          final box = queueState.listRenderBox;
          if (box != null) {
            final rect = box.localToGlobal(Offset.zero) & box.size;
            final inflatedRect = rect.inflate(behavior.escapeThresholdInPixels);
            isEscaped = !inflatedRect.contains(pointer);
          }
        }

        if (isEscaped) {
          final relocateZones = _getZones(
            behavior,
            widget.notification.queue.position,
          );
          final passedThreshold = _passedThreshold(
            pointer,
            behavior.thresholdInPixels,
            relocateZones,
          );

          return OverlayPortal(
            controller: _overlayPortalController,
            overlayChildBuilder: (final context) => LayoutBuilder(
              builder: (final context, final constraints) => _RelocationTargets(
                targets: behavior.positions,
                currentPosition: widget.notification.queue.position,
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
        } else {
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
        }
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
