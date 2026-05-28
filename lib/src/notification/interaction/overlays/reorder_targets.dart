part of '../../notification.dart';

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
              _SlotReticle(
                isSelfSlot: widget.zones[i].targetIndex == widget.draggedIndex,
                zone: widget.zones[i],
                pointer: pointer,
                isNearest: nearestIndex == i,
                passedThreshold: widget.passedThreshold,
                ghostChild: widget.ghostChild,
              ),
          ],
        );
      },
    );
  }
}

// --------------------------------───----------------------------------------
// _SlotReticle — three-stage slot visual (formerly _SlotIndicator)
// --------------------------------───----------------------------------------

/// Visual indicator for a single reorder slot.
///
/// Animates through three stages based on pointer proximity and commit state:
///
/// | **Idle**      | Not nearest / `progress == 0` | Hairline + faded  |
/// | **Engaged**   | Nearest, `progress > 0.15`   | Blue pill + label |
/// | **Committed** | `passedThreshold`             | Green + glow      |
///
/// Drop resolution is handled by [DraggableTransitionsState] in `onDragEnd` —
/// this widget is purely visual with no callbacks.
class _SlotReticle extends StatelessWidget {
  const _SlotReticle({
    required this.isSelfSlot,
    required this.zone,
    required this.pointer,
    required this.isNearest,
    required this.passedThreshold,
    required this.ghostChild,
  });

  final bool isSelfSlot;
  final SlotDropZone zone;
  final Offset? pointer;
  final bool isNearest;
  final bool passedThreshold;

  /// Ghost notification widget shown inside the committed slot indicator,
  /// creating the magnetic-lock illusion of the card snapping into place.
  final Widget ghostChild;

  @override
  Widget build(final BuildContext context) {
    final targetBounds = zone.targetBounds;
    if (targetBounds == null) {
      return const SizedBox.shrink();
    }

    // Self-slot: completely invisible, no interaction target needed.
    if (isSelfSlot) {
      return Positioned.fromRect(
        rect: targetBounds,
        child: const SizedBox.shrink(),
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Reticle & Recess ──────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: engaged ? recessColor : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: engaged ? borderColor : Colors.transparent,
                width: engaged ? 2.0 : 0.0,
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
      ),
    );
  }
}
