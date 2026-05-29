part of '../notification.dart';

/// Defines the operational and rendering contract for all gestural interactions.
abstract class NotificationGesturePlugin {
  const NotificationGesturePlugin();

  /// Invoked when the drag gesture transaction is initiated.
  void onDragStart(final DraggableTransitionsState state);

  /// Invoked upon active movement updates of the pointer.
  void onDragUpdate(
    final DraggableTransitionsState state,
    final DragUpdateDetails details,
  );

  /// Invoked when the pointer is released.
  void onDragEnd(
    final DraggableTransitionsState state,
    final DraggableDetails details,
  );

  /// Generates the visual feedback and reactive overlays wrapping the dragged card.
  Widget buildFeedback(
    final DraggableTransitionsState state,
    final OffsetPair? offsetPair,
  );
}

/// Gesture plugin implementing swipe-to-dismiss behavior.
class DismissGesturePlugin extends NotificationGesturePlugin {
  const DismissGesturePlugin({required this.behavior});

  final Dismiss behavior;

  @override
  void onDragStart(final DraggableTransitionsState state) {
    final position = state.widget.notification.queue.position;
    FlutterNotificationQueue.coordinator.bringToFront(position);
    state.widget.notification.key.currentState?.ditchDismissTimer();
    state._dragOffsetPairNotifier.value = OffsetPair(
      local: Offset.zero,
      global: state._dragStartData?.pointerPosition ?? Offset.zero,
    );
    state._overlayPortalController.show();
  }

  @override
  void onDragUpdate(
    final DraggableTransitionsState state,
    final DragUpdateDetails details,
  ) {
    state._dragOffsetPairNotifier.value = OffsetPair(
      local: details.delta,
      global: details.globalPosition,
    );
  }

  @override
  void onDragEnd(
    final DraggableTransitionsState state,
    final DraggableDetails details,
  ) {
    final pointer = state._dragOffsetPairNotifier.value?.global;
    final position = state.widget.notification.queue.position;
    if (pointer != null) {
      final zones = state._getZones(behavior, position);
      final isHit = zones.any(
        (final z) => z.isHit(
          pointer,
          state._screenSize,
          behavior.thresholdInPixels.toDouble(),
        ),
      );
      if (isHit) {
        HapticFeedback.mediumImpact();
        state.widget.notification.key.currentState?.dismiss();
      }
    }
    state._dragOffsetPairNotifier.value = null;
    state.widget.notification.key.currentState?.initDismissTimer();
    state._overlayPortalController.hide();
  }

  @override
  Widget buildFeedback(
    final DraggableTransitionsState state,
    final OffsetPair? offsetPair,
  ) {
    final pointer = offsetPair?.global;
    final position = state.widget.notification.queue.position;
    final zones = state._getZones(behavior, position);
    final passedThreshold = state._passedThreshold(
      pointer,
      behavior.thresholdInPixels,
      zones,
    );

    return OverlayPortal(
      controller: state._overlayPortalController,
      overlayChildBuilder: (final context) => LayoutBuilder(
        builder: (final context, final constraints) => _DismissalTargets(
          screenSize: constraints.biggest,
          threshold: behavior.thresholdInPixels.toDouble(),
          zones: zones.cast<EdgeDropZone>(),
          pointerPositionNotifier: state._dragOffsetPairNotifier,
        ),
      ),
      child: _DismissFeedbackOverlay(
        passedThreshold: passedThreshold,
        dragOffset: pointer,
        thresholdInPixels: behavior.thresholdInPixels,
        screenSize: state._screenSize,
        startData: state._dragStartData,
        zones: zones.cast<EdgeDropZone>(),
        springPhysics: behavior.springPhysics,
        child: state.widget.notification,
      ),
    );
  }
}

/// Gesture plugin implementing queue relocation behavior.
class RelocateGesturePlugin extends NotificationGesturePlugin {
  const RelocateGesturePlugin({required this.behavior});

  final Relocate behavior;

  @override
  void onDragStart(final DraggableTransitionsState state) {
    final position = state.widget.notification.queue.position;
    FlutterNotificationQueue.coordinator.bringToFront(position);
    state.widget.notification.key.currentState?.ditchDismissTimer();
    state._dragOffsetPairNotifier.value = OffsetPair(
      local: Offset.zero,
      global: state._dragStartData?.pointerPosition ?? Offset.zero,
    );
    state._overlayPortalController.show();
  }

  @override
  void onDragUpdate(
    final DraggableTransitionsState state,
    final DragUpdateDetails details,
  ) {
    state._dragOffsetPairNotifier.value = OffsetPair(
      local: details.delta,
      global: details.globalPosition,
    );
  }

  @override
  void onDragEnd(
    final DraggableTransitionsState state,
    final DraggableDetails details,
  ) {
    final pointer = state._dragOffsetPairNotifier.value?.global;
    final position = state.widget.notification.queue.position;
    if (pointer != null) {
      final zones = state._getZones(behavior, position);
      final hitZone = zones
          .cast<PositionDropZone>()
          .where(
            (final z) => z.isHit(
              pointer,
              state._screenSize,
              behavior.thresholdInPixels.toDouble(),
            ),
          )
          .firstOrNull;
      if (hitZone != null) {
        HapticFeedback.mediumImpact();
        FlutterNotificationQueue.coordinator
            .relocate(state.widget.notification, hitZone.position);
      }
    }
    state._dragOffsetPairNotifier.value = null;
    state.widget.notification.key.currentState?.initDismissTimer();
    state._overlayPortalController.hide();
  }

  @override
  Widget buildFeedback(
    final DraggableTransitionsState state,
    final OffsetPair? offsetPair,
  ) {
    final pointer = offsetPair?.global;
    final position = state.widget.notification.queue.position;
    final zones = state._getZones(behavior, position);
    final passedThreshold = state._passedThreshold(
      pointer,
      behavior.thresholdInPixels,
      zones,
    );

    return OverlayPortal(
      controller: state._overlayPortalController,
      overlayChildBuilder: (final context) => LayoutBuilder(
        builder: (final context, final constraints) => _RelocationTargets(
          targets: behavior.positions,
          currentPosition: position,
          screenSize: constraints.biggest,
          pointerPositionNotifier: state._dragOffsetPairNotifier,
          threshold: behavior.thresholdInPixels.toDouble(),
        ),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOut,
        opacity: passedThreshold ? 0.3 : 1.0,
        child: state.widget.notification,
      ),
    );
  }
}

/// Gesture plugin implementing list stack reordering behavior.
class ReorderGesturePlugin extends NotificationGesturePlugin {
  const ReorderGesturePlugin({required this.behavior});

  final Reorder behavior;

  @override
  void onDragStart(final DraggableTransitionsState state) {
    final position = state.widget.notification.queue.position;
    final queueKey =
        FlutterNotificationQueue.coordinator.getWidgetKey(position);
    final queueState = queueKey.currentState;
    final itemCount = queueState?.itemCount ?? 1;
    final currentIndex = queueState?.indexOf(state.widget.notification) ?? 0;

    FlutterNotificationQueue.coordinator.bringToFront(position);
    state.widget.notification.key.currentState?.ditchDismissTimer();
    state
      .._activeZoneIndex = null
      .._activeReorderZones = _zonesFromSlots(itemCount, currentIndex)
      .._dragOffsetPairNotifier.value = OffsetPair(
        local: Offset.zero,
        global: state._dragStartData?.pointerPosition ?? Offset.zero,
      )
      .._overlayPortalController.show();
  }

  @override
  void onDragUpdate(
    final DraggableTransitionsState state,
    final DragUpdateDetails details,
  ) {
    state._dragOffsetPairNotifier.value = OffsetPair(
      local: details.delta,
      global: details.globalPosition,
    );
  }

  @override
  void onDragEnd(
    final DraggableTransitionsState state,
    final DraggableDetails details,
  ) {
    final pointer = state._dragOffsetPairNotifier.value?.global;
    if (pointer != null) {
      final zones = state._activeReorderZones ?? [];
      final passedThreshold = state._passedThreshold(
        pointer,
        behavior.thresholdInPixels,
        zones,
      );
      if (passedThreshold) {
        final nearestZoneIdx =
            state._nearestZoneIndexWithHysteresis(pointer, zones);
        if (nearestZoneIdx != null) {
          HapticFeedback.mediumImpact();
          FlutterNotificationQueue.coordinator.reorder(
            state.widget.notification,
            zones[nearestZoneIdx].targetIndex,
          );
        }
      }
    }
    state._activeReorderZones = null;
    state._dragOffsetPairNotifier.value = null;
    state._activeZoneIndex = null;
    state.widget.notification.key.currentState?.initDismissTimer();
    state._overlayPortalController.hide();
  }

  @override
  Widget buildFeedback(
    final DraggableTransitionsState state,
    final OffsetPair? offsetPair,
  ) {
    final pointer = offsetPair?.global;
    final position = state.widget.notification.queue.position;
    final queueKey =
        FlutterNotificationQueue.coordinator.getWidgetKey(position);
    final queueState = queueKey.currentState;
    final currentIndex = queueState?.indexOf(state.widget.notification) ?? 0;

    final zones = state._activeReorderZones ?? [];
    final passedThreshold = state._passedThreshold(
      pointer,
      behavior.thresholdInPixels,
      zones,
    );
    final nearestProgress = state._nearestZoneProgress(pointer, zones);
    final nearestIndex = state._nearestZoneIndexWithHysteresis(pointer, zones);

    return OverlayPortal(
      controller: state._overlayPortalController,
      overlayChildBuilder: (final context) => LayoutBuilder(
        builder: (final context, final constraints) => _ReorderTargets(
          draggedIndex: currentIndex,
          zones: zones,
          itemKeys: queueState?.itemGlobalKeys ?? [],
          passedThreshold: passedThreshold,
          nearestIndex: nearestIndex,
          pointerPositionNotifier: state._dragOffsetPairNotifier,
          ghostChild: state._buildDummyGhost(
            state._dragStartData?.widgetSize ?? Size.zero,
          ),
        ),
      ),
      child: _LiftedFeedback(
        passedThreshold: passedThreshold,
        nearestProgress: nearestProgress,
        widgetSize: state._dragStartData?.widgetSize ?? Size.zero,
        springPhysics: behavior.springPhysics,
        child: state.widget.notification,
      ),
    );
  }
}

/// Gesture plugin implementing hybrid reorder-relocate behavior.
class ReorderRelocateGesturePlugin extends NotificationGesturePlugin {
  const ReorderRelocateGesturePlugin({required this.behavior});

  final ReorderAndRelocate behavior;

  @override
  void onDragStart(final DraggableTransitionsState state) {
    final position = state.widget.notification.queue.position;
    final queueKey =
        FlutterNotificationQueue.coordinator.getWidgetKey(position);
    final queueState = queueKey.currentState;
    final itemCount = queueState?.itemCount ?? 1;
    final currentIndex = queueState?.indexOf(state.widget.notification) ?? 0;

    FlutterNotificationQueue.coordinator.bringToFront(position);
    state.widget.notification.key.currentState?.ditchDismissTimer();
    state
      .._activeZoneIndex = null
      .._activeReorderZones = _zonesFromSlots(itemCount, currentIndex)
      .._dragOffsetPairNotifier.value = OffsetPair(
        local: Offset.zero,
        global: state._dragStartData?.pointerPosition ?? Offset.zero,
      )
      .._overlayPortalController.show();
  }

  @override
  void onDragUpdate(
    final DraggableTransitionsState state,
    final DragUpdateDetails details,
  ) {
    state._dragOffsetPairNotifier.value = OffsetPair(
      local: details.delta,
      global: details.globalPosition,
    );
  }

  @override
  void onDragEnd(
    final DraggableTransitionsState state,
    final DraggableDetails details,
  ) {
    final pointer = state._dragOffsetPairNotifier.value?.global;
    final position = state.widget.notification.queue.position;
    if (pointer != null) {
      final reorderZones = state._activeReorderZones ?? [];
      final passedThreshold = state._passedThreshold(
        pointer,
        behavior.thresholdInPixels,
        reorderZones,
      );

      if (passedThreshold) {
        final nearestZoneIdx =
            state._nearestZoneIndexWithHysteresis(pointer, reorderZones);
        if (nearestZoneIdx != null) {
          HapticFeedback.mediumImpact();
          FlutterNotificationQueue.coordinator.reorder(
            state.widget.notification,
            reorderZones[nearestZoneIdx].targetIndex,
          );
        }
      } else {
        final relocateZones = state
            ._getZones(
              behavior,
              position,
            )
            .cast<PositionDropZone>();

        final hitPosition = relocateZones
            .where(
              (final z) => z.isHit(
                pointer,
                state._screenSize,
                behavior.thresholdInPixels.toDouble(),
              ),
            )
            .firstOrNull;

        if (hitPosition != null) {
          HapticFeedback.mediumImpact();
          FlutterNotificationQueue.coordinator
              .relocate(state.widget.notification, hitPosition.position);
        }
      }
    }
    state._activeReorderZones = null;
    state._dragOffsetPairNotifier.value = null;
    state._activeZoneIndex = null;
    state.widget.notification.key.currentState?.initDismissTimer();
    state._overlayPortalController.hide();
  }

  @override
  Widget buildFeedback(
    final DraggableTransitionsState state,
    final OffsetPair? offsetPair,
  ) {
    final pointer = offsetPair?.global;
    final position = state.widget.notification.queue.position;
    final queueKey =
        FlutterNotificationQueue.coordinator.getWidgetKey(position);
    final queueState = queueKey.currentState;
    final currentIndex = queueState?.indexOf(state.widget.notification) ?? 0;

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
      final relocateZones = state._getZones(
        behavior,
        position,
      );
      final passedThreshold = state._passedThreshold(
        pointer,
        behavior.thresholdInPixels,
        relocateZones,
      );

      return OverlayPortal(
        controller: state._overlayPortalController,
        overlayChildBuilder: (final context) => LayoutBuilder(
          builder: (final context, final constraints) => _RelocationTargets(
            targets: behavior.positions,
            currentPosition: position,
            screenSize: constraints.biggest,
            pointerPositionNotifier: state._dragOffsetPairNotifier,
            threshold: behavior.thresholdInPixels.toDouble(),
          ),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOut,
          opacity: passedThreshold ? 0.3 : 1.0,
          child: state.widget.notification,
        ),
      );
    } else {
      final zones = state._activeReorderZones ?? [];
      final passedThreshold = state._passedThreshold(
        pointer,
        behavior.thresholdInPixels,
        zones,
      );
      final nearestProgress = state._nearestZoneProgress(pointer, zones);
      final nearestIndex =
          state._nearestZoneIndexWithHysteresis(pointer, zones);

      return OverlayPortal(
        controller: state._overlayPortalController,
        overlayChildBuilder: (final context) => LayoutBuilder(
          builder: (final context, final constraints) => _ReorderTargets(
            draggedIndex: currentIndex,
            zones: zones,
            itemKeys: queueState?.itemGlobalKeys ?? [],
            passedThreshold: passedThreshold,
            nearestIndex: nearestIndex,
            pointerPositionNotifier: state._dragOffsetPairNotifier,
            ghostChild: state._buildDummyGhost(
              state._dragStartData?.widgetSize ?? Size.zero,
            ),
          ),
        ),
        child: _LiftedFeedback(
          passedThreshold: passedThreshold,
          nearestProgress: nearestProgress,
          widgetSize: state._dragStartData?.widgetSize ?? Size.zero,
          springPhysics: behavior.springPhysics,
          child: state.widget.notification,
        ),
      );
    }
  }
}
