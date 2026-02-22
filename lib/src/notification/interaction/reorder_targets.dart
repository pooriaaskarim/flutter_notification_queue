part of '../notification.dart';

// Identity matrix — no color change.
const List<double> _kIdentityMatrix = [
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 1, 0,
];

// 50% desaturation — engaged (approaching a slot).
const List<double> _kSlightDesatMatrix = [
  0.67, 0.21, 0.07, 0, 0, //
  0.17, 0.72, 0.07, 0, 0,
  0.17, 0.21, 0.57, 0, 0,
  0.00, 0.00, 0.00, 1, 0,
];

// ~80% desaturation — committed (will drop on release).
const List<double> _kDesatMatrix = [
  0.33, 0.34, 0.33, 0, 0, //
  0.33, 0.34, 0.33, 0, 0,
  0.33, 0.34, 0.33, 0, 0,
  0.00, 0.00, 0.00, 1, 0,
];

// ---------------------------------------------------------------------------
// _ReorderOverlay
// ---------------------------------------------------------------------------

/// Full-screen overlay rendered during a reorder drag.
///
/// Owns the three-stage slot indicator logic and the anchor computation
/// lifecycle. Rebuilds whenever the pointer moves via
/// [pointerPositionNotifier].
class _ReorderTargets extends StatefulWidget {
  const _ReorderTargets({
    required this.draggedIndex,
    required this.zones,
    required this.itemKeys,
    required this.onAccept,
    required this.passedThreshold,
    required this.pointerPositionNotifier,
    required this.ghostChild,
  });

  /// The original queue index of the item currently being dragged.
  final int draggedIndex;

  /// The slot zones produced by [_zonesFromSlots]. Anchors are written into
  /// these zones after layout.
  final List<SlotDropZone> zones;

  /// One [GlobalKey] per active notification widget, in stack order.
  final List<GlobalKey> itemKeys;

  /// Called when a valid drop is committed to a slot.
  final void Function(int targetIndex) onAccept;

  /// Whether the drag interaction has passed the proximity threshold.
  final bool passedThreshold;

  /// Tracks the pointer's global position and local delta during drag events.
  final ValueNotifier<OffsetPair?> pointerPositionNotifier;

  /// Ghost notification widget shown inside the committed indicator.
  final Widget ghostChild;

  @override
  State<_ReorderTargets> createState() => _ReorderTargetsState();
}

class _ReorderTargetsState extends State<_ReorderTargets> {
  /// The index of the drop zone that is currently magnetically locked.
  /// Used to exert an artificial "gravity well" to prevent UI jitter.
  int? _currentActiveZone;

  /// Returns the screen-space bounding box of a rendered notification widget.
  Rect? _boundsOf(final GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) {
      return null;
    }
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  int? _nearestZoneIndex(final Offset pointer) {
    int? best;
    double bestDist = double.infinity;

    // Hysteresis physics: apply an artificial gravity well (- distance)
    // to the CURRENTLY ACTIVE zone. The pointer must drag significantly further
    // away from the active center to break the lock, completely eliminating
    // bound-jitter regardless of pointer velocity or micro-vibrations.
    const double gravityWell = 40.0;

    for (var i = 0; i < widget.zones.length; i++) {
      final anchor = widget.zones[i].anchor;
      if (anchor == null) {
        continue;
      }

      double dist = (anchor - pointer).distance;

      if (i == _currentActiveZone) {
        dist -= gravityWell;
      }

      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }

    _currentActiveZone = best;
    return best;
  }

  @override
  Widget build(final BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      for (var i = 0; i < widget.zones.length; i++) {
        Rect? bounds;

        if (i < widget.itemKeys.length) {
          bounds = _boundsOf(widget.itemKeys[i]);
        }

        if (bounds != null) {
          widget.zones[i].setTargetBounds(bounds);
        }
      }
    });

    return ValueListenableBuilder(
      valueListenable: widget.pointerPositionNotifier,
      builder: (final context, final offsetPair, final child) {
        final pointer = offsetPair?.global;
        final nearestIndex =
            pointer == null ? null : _nearestZoneIndex(pointer);

        return Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < widget.zones.length; i++)
              _SlotIndicator(
                isSelfSlot: widget.zones[i].targetIndex == widget.draggedIndex,
                zone: widget.zones[i],
                pointer: pointer,
                isNearest: nearestIndex == i,
                passedThreshold: widget.passedThreshold,
                onAccept: () => widget.onAccept(i),
                ghostChild: widget.ghostChild,
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _ReorderPlaceholder
// ---------------------------------------------------------------------------

/// A ghost widget shown in the queue where the dragged notification used to be.
///
/// Uses a frosted-glass, dashed-border card to clearly communicate that a
/// notification has been lifted from this slot and is being repositioned.
class _ReorderPlaceholder extends StatefulWidget {
  const _ReorderPlaceholder({required this.child});

  /// The original notification widget — used only to measure its layout size
  /// (invisible, wrapped in `Opacity(0)`).
  final Widget child;

  @override
  State<_ReorderPlaceholder> createState() => _ReorderPlaceholderState();
}

class _ReorderPlaceholderState extends State<_ReorderPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
        animation: _pulse,
        builder: (final context, final child) {
          final opacity = 0.35 + _pulse.value * 0.25;
          return Opacity(
            opacity: opacity,
            child: Stack(
              children: [
                // Notification content ghosted at low opacity so the user can
                // see which card has been lifted from this slot.
                //
                // Crucially, wrap in ExcludeSemantics and IgnorePointer because
                // the exact same widget instance is also mounted in the
                // Draggable feedback overlay. Flutter's semantics tree throws
                // assertions if the same node is active in multiple places.
                ExcludeSemantics(
                  child: IgnorePointer(
                    child: Opacity(opacity: 0.35, child: widget.child),
                  ),
                ),
                // Ghost overlay.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DashedBorderPainter(
                      opacity: opacity,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

/// Draws a rounded-rect dashed border as the ghost placeholder outline.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.opacity});

  final double opacity;

  @override
  void paint(final Canvas canvas, final Size size) {
    const radius = Radius.circular(12);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
      radius,
    );
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    _drawDashedRRect(canvas, rrect, paint);
  }

  void _drawDashedRRect(
    final Canvas canvas,
    final RRect rrect,
    final Paint paint,
  ) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end as double), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(final _DashedBorderPainter old) => old.opacity != opacity;
}

// ---------------------------------------------------------------------------
// _LiftedFeedback
// ---------------------------------------------------------------------------

/// Wraps the dragged notification to give it a "lifted" appearance.
///
/// Applies elevation shadow, slight scale, and a subtle tilt based on the
/// drag stage:
/// - **Stage 1** (idle): scale 1.04, shadow, no tint.
/// - **Stage 2** (proximity): scale 1.06, stronger shadow, blue border glow.
/// - **Stage 3** (committed): scale 0.97, green glow, dimmed opacity.
class _LiftedFeedback extends StatelessWidget {
  const _LiftedFeedback({
    required this.child,
    required this.passedThreshold,
    required this.nearestProgress,
    required this.widgetSize,
  });

  final Widget child;
  final bool passedThreshold;
  final double nearestProgress;

  /// The original on-screen size of the notification widget.
  ///
  /// Required because the Draggable `feedback` widget runs in an unconstrained
  /// overlay context. Without explicit dimensions the notification collapses to
  /// its minimum intrinsic size (a thin line).
  final Size widgetSize;

  @override
  Widget build(final BuildContext context) {
    final bool engaged = nearestProgress > 0.3;

    final double scale = passedThreshold
        ? 0.96
        : engaged
            ? 1.06
            : 1.04;

    final double opacity = passedThreshold ? 0.5 : 1.0;

    final Color glowColor = passedThreshold
        ? Colors.green
        : engaged
            ? Colors.blue
            : Colors.transparent;

    final double glowSpread = passedThreshold
        ? 4.0
        : engaged
            ? 2.0
            : 0.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: widgetSize.width,
          height: widgetSize.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: passedThreshold ? 4 : 20,
                spreadRadius: passedThreshold ? 0 : 4,
                offset: const Offset(0, 8),
              ),
              if (engaged)
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: glowSpread,
                ),
            ],
          ),
          // ClipRRect ensures the notification content is bounded by the card's
          // rounded corners rather than overflowing the glowing frame.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ColorFiltered(
              // Slight desaturation subtly signals "I'm a lifted copy".
              colorFilter: ColorFilter.matrix(
                passedThreshold
                    ? _kDesatMatrix
                    : engaged
                        ? _kSlightDesatMatrix
                        : _kIdentityMatrix,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SlotIndicator — three-stage slot visual
// ---------------------------------------------------------------------------

/// Visual indicator for a single reorder slot.
///
/// Animates through three stages based on pointer proximity and commit state:
///
/// | **Idle**      | Not nearest / `progress == 0` | Hairline + faded  |
/// | **Engaged**   | Nearest, `progress > 0.15`   | Blue pill + label |
/// | **Committed** | `passedThreshold`             | Green + glow      |
class _SlotIndicator extends StatelessWidget {
  const _SlotIndicator({
    required this.isSelfSlot,
    required this.zone,
    required this.pointer,
    required this.isNearest,
    required this.passedThreshold,
    required this.onAccept,
    required this.ghostChild,
  });

  final bool isSelfSlot;
  final SlotDropZone zone;
  final Offset? pointer;
  final bool isNearest;
  final bool passedThreshold;
  final VoidCallback onAccept;

  /// Ghost notification widget shown inside the committed slot indicator,
  /// creating the magnetic-lock illusion of the card snapping into place.
  final Widget ghostChild;

  @override
  Widget build(final BuildContext context) {
    final targetBounds = zone.targetBounds;
    if (targetBounds == null) {
      return const SizedBox.shrink();
    }

    // A notification should not show a visual target for dropping onto itself.
    if (isSelfSlot) {
      return Positioned.fromRect(
        rect: targetBounds,
        child: DragTarget<int>(
          hitTestBehavior: HitTestBehavior.opaque,
          onWillAcceptWithDetails: (final _) => true,
          onAcceptWithDetails: (final _) {
            if (passedThreshold) {
              onAccept();
            }
          },
          builder: (final context, final candidateData, final rejectedData) =>
              const SizedBox.shrink(), // Completely invisible
        ),
      );
    }

    final double progress = pointer == null || !isNearest
        ? 0.0
        : zone.calculateProgress(pointer!, 1.0 / 120.0);

    final bool engaged = isNearest && progress > 0.15;
    final bool committed = passedThreshold && engaged;

    // Reticle/Recess styling
    final Color borderColor = committed
        ? Colors.green.withValues(alpha: 0.8)
        : engaged
            ? Colors.blue.withValues(alpha: 0.6)
            : Colors.transparent;

    final Color recessColor = committed
        ? Colors.black.withValues(alpha: 0.4)
        : engaged
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.transparent;

    return Positioned.fromRect(
      rect: targetBounds,
      child: DragTarget<int>(
        hitTestBehavior: HitTestBehavior.opaque,
        onWillAcceptWithDetails: (final _) => true,
        onAcceptWithDetails: passedThreshold ? (final _) => onAccept() : null,
        builder: (final context, final candidateData, final rejectedData) {
          final bool isDragOver = candidateData.isNotEmpty;
          final bool active = engaged || isDragOver;

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Reticle & Recess ──────────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: active ? recessColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active ? borderColor : Colors.transparent,
                    width: active ? 2.0 : 0.0,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                  boxShadow: [
                    if (committed)
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.25),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    else if (engaged)
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.15),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                  ],
                ),
              ),
              // ── Magnetic Lock Ghost ───────────────────────────────────────
              // When locked in, show a ghost of the notification card exactly
              // filling the bounds of the target slot.
              if (committed)
                Center(
                  child: Opacity(
                    opacity: 0.55,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix(_kDesatMatrix),
                      child: ExcludeSemantics(
                        child: IgnorePointer(
                          child: ghostChild,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
