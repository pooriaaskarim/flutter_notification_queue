part of '../notification.dart';

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

class DraggableTransitionsState extends State<DraggableTransitions> {
  late Size _screenSize;

  final ValueNotifier<OffsetPair?> _dragOffsetPairNotifier =
      ValueNotifier(null);

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

    super.dispose();
  }

  // Derives the active edge zones based on the interaction behavior.
  //
  // - Dismiss: uses DismissZone policy + current position.
  // - Relocate: derives zones from the set of target positions, correctly
  //   marking home-edges as isNatural to prevent hair-trigger engagement.
  // - Disabled: returns empty (unreachable in practice).
  List<EdgeDropZone> _getZones(
    final QueueNotificationBehavior behavior,
    final QueuePosition position,
  ) {
    if (behavior is Dismiss) {
      return _edgesFromDismissZone(behavior.zones, position);
    } else if (behavior is Relocate) {
      return _edgesFromPositions(behavior.positions, position);
    }
    return [];
  }

  bool _passedThreshold(
    final Offset? globalOffset,
    final int thresholdInPixels,
    final List<EdgeDropZone> zones,
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

  Widget longPressWidget() =>
      switch (widget.notification.queue.longPressDragBehavior) {
        Relocate() => LongPressDraggable<QueuePosition>(
            data: widget.notification.queue.position,
            axis: null,
            onDragStarted: () {
              FlutterNotificationQueue.coordinator
                  .bringToFront(widget.notification.queue.position);
              widget.notification.key.currentState?.ditchDismissTimer();
              if (widget.notification.queue.longPressDragBehavior
                  is! Disabled) {
                _overlayPortalController.show();
              }
            },
            onDragUpdate: (final details) {
              if (widget.notification.queue.longPressDragBehavior
                  is! Disabled) {
                _dragOffsetPairNotifier.value = OffsetPair(
                  local: details.delta,
                  global: details.globalPosition,
                );
              }
            },
            onDragEnd: (final details) {
              _dragOffsetPairNotifier.value = null;
              widget.notification.key.currentState?.initDismissTimer();
              if (widget.notification.queue.longPressDragBehavior
                  is! Disabled) {
                _overlayPortalController.hide();
              }
            },
            maxSimultaneousDrags: 1,
            hapticFeedbackOnStart: widget.hapticFeedbackOnStart,
            hitTestBehavior: HitTestBehavior.deferToChild,
            childWhenDragging: const SizedBox.shrink(),
            feedback: ValueListenableBuilder(
              valueListenable: _dragOffsetPairNotifier,
              builder: (final context, final dragOffestPair, final child) {
                final behavior =
                    widget.notification.queue.longPressDragBehavior as Relocate;
                final zones = _getZones(
                  behavior,
                  widget.notification.queue.position,
                );
                final passedThreshold = _passedThreshold(
                  dragOffestPair?.global,
                  behavior.thresholdInPixels,
                  zones,
                );

                return OverlayPortal(
                  controller: _overlayPortalController,
                  overlayChildBuilder: (final context) => LayoutBuilder(
                    builder: (final context, final constraints) =>
                        _RelocationTargets(
                      targets: behavior.positions,
                      currentPosition: widget.notification.queue.position,
                      onAccept: (final candidatePosition) {
                        FlutterNotificationQueue.coordinator
                            .relocate(widget.notification, candidatePosition);
                      },
                      screenSize: constraints.biggest,
                      passedThreshold: passedThreshold,
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
            ),
            child: draggable(),
          ),
        Dismiss() => LongPressDraggable<AlignmentGeometry>(
            data: widget.notification.queue.position.alignment,
            axis: null,
            onDragStarted: () {
              FlutterNotificationQueue.coordinator
                  .bringToFront(widget.notification.queue.position);
              widget.notification.key.currentState?.ditchDismissTimer();
              if (widget.notification.queue.longPressDragBehavior
                  is! Disabled) {
                _overlayPortalController.show();
              }
            },
            onDragUpdate: (final details) {
              if (widget.notification.queue.longPressDragBehavior
                  is! Disabled) {
                _dragOffsetPairNotifier.value = OffsetPair(
                  local: details.delta,
                  global: details.globalPosition,
                );
              }
            },
            onDragEnd: (final details) {
              _dragOffsetPairNotifier.value = null;
              widget.notification.key.currentState?.initDismissTimer();
              if (widget.notification.queue.longPressDragBehavior
                  is! Disabled) {
                _overlayPortalController.hide();
              }
            },
            maxSimultaneousDrags: 1,
            hapticFeedbackOnStart: widget.hapticFeedbackOnStart,
            hitTestBehavior: HitTestBehavior.deferToChild,
            childWhenDragging: const SizedBox.shrink(),
            feedback: ValueListenableBuilder(
              valueListenable: _dragOffsetPairNotifier,
              builder: (final context, final dragOffestPair, final child) {
                final behavior =
                    widget.notification.queue.longPressDragBehavior as Dismiss;
                final zones = _getZones(
                  behavior,
                  widget.notification.queue.position,
                );
                final passedThreshold = _passedThreshold(
                  dragOffestPair?.global,
                  behavior.thresholdInPixels,
                  zones,
                );

                return OverlayPortal(
                  controller: _overlayPortalController,
                  overlayChildBuilder: (final context) => LayoutBuilder(
                    builder: (final context, final constraints) =>
                        _DismissalTargets(
                      onAccept: () {
                        widget.notification.key.currentState?.dismiss();
                      },
                      screenSize: constraints.biggest,
                      threshold: behavior.thresholdInPixels.toDouble(),
                      zones: zones,
                      pointerPositionNotifier: _dragOffsetPairNotifier,
                    ),
                  ),
                  child: _DismissFeedbackOverlay(
                    passedThreshold: passedThreshold,
                    dragOffset: dragOffestPair?.global,
                    thresholdInPixels: behavior.thresholdInPixels,
                    screenSize: _screenSize,
                    startData: _dragStartData,
                    zones: zones,
                    child: widget.notification,
                  ),
                );
              },
            ),
            child: draggable(),
          ),
        Disabled() => draggable(),
      };

  Widget draggable() => switch (widget.notification.queue.dragBehavior) {
        Relocate() => Draggable<QueuePosition>(
            data: widget.notification.queue.position,
            axis: null,
            onDragStarted: () {
              FlutterNotificationQueue.coordinator
                  .bringToFront(widget.notification.queue.position);
              widget.notification.key.currentState?.ditchDismissTimer();
              if (widget.notification.queue.dragBehavior is! Disabled) {
                _overlayPortalController.show();
              }
            },
            onDragUpdate: (final details) {
              if (widget.notification.queue.dragBehavior is! Disabled) {
                _dragOffsetPairNotifier.value = OffsetPair(
                  local: details.delta,
                  global: details.globalPosition,
                );
              }
            },
            onDragEnd: (final details) {
              _dragOffsetPairNotifier.value = null;
              widget.notification.key.currentState?.initDismissTimer();
              if (widget.notification.queue.dragBehavior is! Disabled) {
                _overlayPortalController.hide();
              }
            },
            maxSimultaneousDrags: 1,
            childWhenDragging: const SizedBox.shrink(),
            feedback: ValueListenableBuilder(
              valueListenable: _dragOffsetPairNotifier,
              builder: (final context, final dragOffestPair, final child) {
                final behavior =
                    widget.notification.queue.dragBehavior as Relocate;
                final zones = _getZones(
                  behavior,
                  widget.notification.queue.position,
                );
                final passedThreshold = _passedThreshold(
                  dragOffestPair?.global,
                  behavior.thresholdInPixels,
                  zones,
                );

                return OverlayPortal(
                  controller: _overlayPortalController,
                  overlayChildBuilder: (final context) => LayoutBuilder(
                    builder: (final context, final constraints) =>
                        _RelocationTargets(
                      targets:
                          (widget.notification.queue.dragBehavior as Relocate)
                              .positions,
                      currentPosition: widget.notification.queue.position,
                      onAccept: (final candidatePosition) {
                        FlutterNotificationQueue.coordinator
                            .relocate(widget.notification, candidatePosition);
                      },
                      screenSize: constraints.biggest,
                      passedThreshold: passedThreshold,
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
            ),
            child: widget.notification,
          ),
        Dismiss() => Draggable<AlignmentGeometry>(
            data: widget.notification.queue.position.alignment,
            axis: null,
            onDragStarted: () {
              FlutterNotificationQueue.coordinator
                  .bringToFront(widget.notification.queue.position);
              widget.notification.key.currentState?.ditchDismissTimer();
              if (widget.notification.queue.dragBehavior is! Disabled) {
                _overlayPortalController.show();
              }
            },
            onDragUpdate: (final details) {
              if (widget.notification.queue.dragBehavior is! Disabled) {
                _dragOffsetPairNotifier.value = OffsetPair(
                  local: details.delta,
                  global: details.globalPosition,
                );
              }
            },
            onDragEnd: (final details) {
              _dragOffsetPairNotifier.value = null;
              widget.notification.key.currentState?.initDismissTimer();
              if (widget.notification.queue.longPressDragBehavior
                  is! Disabled) {
                _overlayPortalController.hide();
              }
            },
            maxSimultaneousDrags: 1,
            childWhenDragging: const SizedBox.shrink(),
            feedback: ValueListenableBuilder(
              valueListenable: _dragOffsetPairNotifier,
              builder: (final context, final dragOffestPair, final child) {
                final behavior =
                    widget.notification.queue.dragBehavior as Dismiss;
                final zones = _getZones(
                  behavior,
                  widget.notification.queue.position,
                );
                final passedThreshold = _passedThreshold(
                  dragOffestPair?.global,
                  behavior.thresholdInPixels,
                  zones,
                );

                return OverlayPortal(
                  controller: _overlayPortalController,
                  overlayChildBuilder: (final context) => LayoutBuilder(
                    builder: (final context, final constraints) =>
                        _DismissalTargets(
                      onAccept: () {
                        widget.notification.key.currentState?.dismiss();
                      },
                      screenSize: constraints.biggest,
                      threshold: behavior.thresholdInPixels.toDouble(),
                      zones: zones,
                      pointerPositionNotifier: _dragOffsetPairNotifier,
                    ),
                  ),
                  child: _DismissFeedbackOverlay(
                    passedThreshold: passedThreshold,
                    dragOffset: dragOffestPair?.global,
                    thresholdInPixels: behavior.thresholdInPixels,
                    screenSize: _screenSize,
                    startData: _dragStartData,
                    zones: zones,
                    child: widget.notification,
                  ),
                );
              },
            ),
            child: widget.notification,
          ),
        Disabled() => widget.notification,
      };
}

class _DragStartData {
  const _DragStartData({
    required this.widgetPosition,
    required this.pointerPosition,
    required this.widgetSize,
  });

  final Offset widgetPosition;
  final Offset pointerPosition;
  final Size widgetSize;

  Offset get touchOffset => pointerPosition - widgetPosition;
}

/// A sophisticated overlay that handles the physical transformation of the
/// Notification Widget during dismissal and relocation interactions.
///
/// This component implements a **Three-Stage Interaction Model**:
///
/// 1.  **Proximity Aura**: As the pointer approaches a dismissal edge, the
///     notification subtly scales down and fades, providing a soft "proximity
///     hint" (Stage 1).
/// 2.  **Engagement (The Void)**: Upon passing the threshold, the notification
///     enters the "Death State", becoming grayscale and slightly blurred to
///     signal commitment (Stage 2).
/// 3.  **Magnet Lock**: While engaged, the notification snaps physically to the
///     outer boundary of the dismissal bar. This "anchors" the action and
///     prevents the widget from obscuring the active zone (Stage 3).
class _DismissFeedbackOverlay extends StatelessWidget {
  const _DismissFeedbackOverlay({
    required this.passedThreshold,
    required this.dragOffset,
    required this.thresholdInPixels,
    required this.screenSize,
    required this.startData,
    required this.zones,
    required this.child,
  });

  final bool passedThreshold;
  final Offset? dragOffset;
  final int thresholdInPixels;
  final Size screenSize;
  final _DragStartData? startData;
  final List<EdgeDropZone> zones;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    EdgeDropZone? lockedZone;
    double proximityProgress = 0.0;

    if (dragOffset != null) {
      final List<double> progressList = [];
      double maxProgress = 0.0;
      EdgeDropZone? maxZone;

      for (final zone in zones) {
        // Calculate the proximity to each dismissal zone.
        final progress = zone.calculateProgress(
          dragOffset!,
          screenSize,
          1.0 / thresholdInPixels,
        );
        progressList.add(progress);

        // Edge Priority: If multiple zones hit the threshold (1.0),
        // we pick the one that is "deeper" into its boundary if we could,
        // but since it's clamped, we keep the FIRST one that hits 1.0
        // to provide stability, or update if another is clearly dominant.
        if (progress >= 1.0 && (lockedZone == null || progress > maxProgress)) {
          lockedZone = zone;
        }

        if (progress > maxProgress) {
          maxProgress = progress;
          maxZone = zone;
        }
      }
      // Use the highest proximity score across all zones to drive visual
      // feedback.
      proximityProgress = progressList.isEmpty ? 0.0 : progressList.reduce(max);

      // FLICKER FIX: If we passed the threshold (via parent logic), we MUST
      // enforce a lockedZone even if current progress dipped slightly below 1.0
      // (hysteresis). We pick the zone with the highest activity.
      if (passedThreshold && lockedZone == null) {
        lockedZone = maxZone;
      }
    }

    Offset correction = Offset.zero;
    if (dragOffset != null && startData != null) {
      correction = _calculateMagnetCorrection(
        dragOffset: dragOffset!,
        startData: startData!,
        lockedZone: lockedZone,
      );
    }

    final double opacity = 1.0 - (proximityProgress * 0.5);
    final double baseScale = 1.0 - (proximityProgress * 0.08);

    // Sinking refinement:
    final double sinkingScale = passedThreshold ? 0.85 : 1.0;
    final double sinkingBlur = passedThreshold ? 4.0 : 0.0;

    final themeData = Theme.of(context);
    final onSurface = themeData.colorScheme.onSurface;

    return Transform.translate(
      offset: correction,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            opacity: opacity,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              scale: baseScale * sinkingScale,
              // Anchoring the scale to the edge makes it feel like it's
              // docking INTO the screen boundary rather than floating.
              alignment: lockedZone?.alignment ?? Alignment.center,
              child: ColorFiltered(
                // The "Death State": Convert to grayscale once the action
                // is committed but not yet released.
                colorFilter: passedThreshold
                    ? ColorUtils.grayscaleFilter
                    : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ImageFiltered(
                    // Visual "Sinking": Soften the widget as it docks.
                    imageFilter: ImageFilter.blur(
                      sigmaX: sinkingBlur,
                      sigmaY: sinkingBlur,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
          if (passedThreshold)
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                opacity: 1.0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                  scale: baseScale * sinkingScale,
                  alignment: lockedZone?.alignment ?? Alignment.center,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            // Premium pure-text legend styled to match the NW
                            // aesthetic.
                            color: themeData.colorScheme.surface
                                .withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: onSurface.withValues(alpha: 0.1),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'RELEASE TO DISMISS',
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Calculates the positional "correction" needed to achieve the Magnet Lock
  /// effect.
  ///
  /// This snaps the notification to the boundary of the dismissal bar when
  /// [lockedZone] is active, or simply clamps it to screen bounds otherwise.
  Offset _calculateMagnetCorrection({
    required final Offset dragOffset,
    required final _DragStartData startData,
    required final EdgeDropZone? lockedZone,
  }) {
    final Offset nominalTopLeft = dragOffset - startData.touchOffset;

    double x = nominalTopLeft.dx
        .clamp(0.0, screenSize.width - startData.widgetSize.width);
    double y = nominalTopLeft.dy
        .clamp(0.0, screenSize.height - startData.widgetSize.height);

    if (passedThreshold && lockedZone != null) {
      final double barSize = thresholdInPixels.toDouble();
      final Alignment align = lockedZone.alignment;

      // Snap logic based on alignment
      if (align.x == -1.0) {
        x = barSize; // Left
      }
      if (align.x == 1.0) {
        x = screenSize.width - startData.widgetSize.width - barSize; // Right
      }
      if (align.y == -1.0) {
        y = barSize; // Top
      }
      if (align.y == 1.0) {
        y = screenSize.height - startData.widgetSize.height - barSize; // Bottom
      }
    }

    return Offset(x, y) - nominalTopLeft;
  }
}
