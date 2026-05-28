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

class DraggableTransitionsState extends State<DraggableTransitions> {
  late Size _screenSize;

  final ValueNotifier<OffsetPair?> _dragOffsetPairNotifier =
      ValueNotifier(null);

  List<SlotDropZone>? _activeReorderZones;

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

  // Derives the active drop zones based on the interaction behavior.
  //
  // - Dismiss: uses DismissZone policy + current position.
  // - Relocate: derives zones from the set of target positions.
  // - Reorder: returns empty — zones are built in the Reorder branch
  //   directly, since item count and index require QueueWidgetState access.
  // - Disabled: returns empty (unreachable in practice).
  List<DropZone> _getZones(
    final QueueNotificationBehavior behavior,
    final QueuePosition position,
  ) {
    if (behavior is Dismiss) {
      return _edgesFromDismissZone(behavior.zones, position);
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

  /// Returns the proximity progress [0.0, 1.0] for the nearest [SlotDropZone].
  ///
  /// Used by [_LiftedFeedback] to pick the correct visual stage without
  /// knowing which specific slot is closest.
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
      switch (widget.notification.queue.longPressDragBehavior) {
        Relocate() => _buildRelocateDraggable(isLongPress: true),
        Dismiss() => _buildDismissDraggable(isLongPress: true),
        Reorder() => _buildReorderDraggable(isLongPress: true),
        ReorderAndRelocate() => _buildUnifiedDraggable(isLongPress: true),
        Disabled() => draggable(),
      };

  Widget draggable() => switch (widget.notification.queue.dragBehavior) {
        Relocate() => _buildRelocateDraggable(isLongPress: false),
        Dismiss() => _buildDismissDraggable(isLongPress: false),
        Reorder() => _buildReorderDraggable(isLongPress: false),
        ReorderAndRelocate() => _buildUnifiedDraggable(isLongPress: false),
        Disabled() => widget.notification,
      };

  /// Creates a visual proxy of the notification card that exactly matches its
  /// captured dimensions on the screen.
  ///
  /// This is critical for Draggable overlay ghosts. Returning the actual
  /// `widget.notification` causes fatal layout errors (e.g. "Tried to build
  /// dirty widget in the wrong build scope") because the real widget instance
  /// possesses a [GlobalObjectKey] that cannot be mounted multiple times.
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
