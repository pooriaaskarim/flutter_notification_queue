part of '../notification.dart';

/// A specialized widget that renders the interactive dismissal targets
/// (auras and engagement bars) for a notification.
///
/// This widget coordinates the "Independent Edge" interaction model, where
/// multiple edges (e.g., in a corner) can be approached, but only one
/// is engaged at a time.
class _DismissalTargets extends StatefulWidget {
  const _DismissalTargets({
    required this.onAccept,
    required this.screenSize,
    required this.threshold,
    required this.zones,
    required this.pointerPositionNotifier,
  });

  /// Callback triggered when the notification is dropped into an active zone.
  final void Function() onAccept;

  /// The width/height threshold of the dismissal bars.
  final double threshold;

  /// The dimensions of the screen for coordinate calculations.
  final Size screenSize;

  /// The list of edges where dismissal can occur.
  final List<InteractionZone> zones;

  /// A notifier providing the current global pointer position.
  final ValueNotifier<OffsetPair?> pointerPositionNotifier;

  @override
  State<_DismissalTargets> createState() => _DismissalTargetsState();
}

class _DismissalTargetsState extends State<_DismissalTargets> {
// No local _dragPosition needed, use parent's notifier

  @override
  void dispose() {
// No local notifier to dispose
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          // Stage 1: The Proximity Aura (Hint State)
          IgnorePointer(
            child: Stack(
              children: [
                for (final zone in widget.zones)
                  _EdgeAura(
                    zone: zone,
                    dragPosition: widget.pointerPositionNotifier,
                    screenSize: widget.screenSize,
                    threshold: widget.threshold,
                  ),
              ],
            ),
          ),

          // Stage 2 & 3: The Stretching Bar (Engagement) &
          // Action Lock (Activation)
          IgnorePointer(
            child: Stack(
              children: [
                for (final zone in widget.zones)
                  _PositionedZone(
                    zone: zone,
                    dragPosition: widget.pointerPositionNotifier,
                    inverseThreshold: 1.0 / widget.threshold,
                    screenSize: widget.screenSize,
                  ),
              ],
            ),
          ),

          // Single global DragTarget
          Positioned.fill(
            child: DragTarget<AlignmentGeometry>(
              hitTestBehavior: HitTestBehavior.opaque,
              onWillAcceptWithDetails: (final details) => true,
              onAcceptWithDetails: (final details) {
                final pointerLocation =
                    widget.pointerPositionNotifier.value?.global;
                if (pointerLocation == null) {
                  return;
                }

                final bool isHit = widget.zones.any(
                  (final zone) => zone.isHit(
                    pointerLocation,
                    widget.screenSize,
                    widget.threshold,
                  ),
                );

                if (isHit) {
                  widget.onAccept();
                }
              },
              builder: (final context, final candidate, final rejected) =>
                  const SizedBox.shrink(),
            ),
          ),
        ],
      );
}

/// A positioned wrapper for the [_InteractionFeedbackZone] that handles the
/// physical placement of the target bar relative to the screen edges.
class _PositionedZone extends StatelessWidget {
  const _PositionedZone({
    required this.zone,
    required this.screenSize,
    required this.inverseThreshold,
    required this.dragPosition,
  });

  final InteractionZone zone;
  final Size screenSize;
  final double inverseThreshold;
  final ValueNotifier<OffsetPair?> dragPosition;

  @override
  Widget build(final BuildContext context) {
    final bool isVertical = zone.axis == Axis.vertical;
    final Alignment alignment = zone.alignment;

    // The cross-axis size is derived from the threshold.
    final double barSize = 1.0 / inverseThreshold;

    return Positioned(
      left: (isVertical && alignment == Alignment.centerLeft) ? 0 : null,
      right: (isVertical && alignment == Alignment.centerRight) ? 0 : null,
      top: (!isVertical && alignment == Alignment.topCenter)
          ? 0
          : (isVertical ? 0 : null),
      bottom: (!isVertical && alignment == Alignment.bottomCenter) ? 0 : null,
      width: isVertical ? barSize : screenSize.width,
      height: isVertical ? screenSize.height : barSize,
      child: _InteractionFeedbackZone(
        zone: zone,
        screenSize: screenSize,
        inverseThreshold: inverseThreshold,
        dragPosition: dragPosition,
      ),
    );
  }
}

/// A core feedback component that displays the dismissal state of a target zone.
///
/// It handles the visual transition from an "Idle" state (pulsing handle) to
/// an "Engaged" state (stretching glass bar with icon).
class _InteractionFeedbackZone extends StatelessWidget {
  const _InteractionFeedbackZone({
    required this.zone,
    required this.screenSize,
    required this.inverseThreshold,
    required this.dragPosition,
  });

  final InteractionZone zone;
  final Size screenSize;
  final double inverseThreshold;
  final ValueNotifier<OffsetPair?> dragPosition;

  @override
  Widget build(final BuildContext context) =>
      ValueListenableBuilder<OffsetPair?>(
        valueListenable: dragPosition,
        builder: (final context, final dragPair, final child) {
          final pointerOffset = dragPair?.global;
          double progress = 0.0;

          if (pointerOffset != null) {
            progress = zone.calculateProgress(
              pointerOffset,
              screenSize,
              inverseThreshold,
            );
          }

          final bool isHit = pointerOffset != null &&
              zone.isHit(pointerOffset, screenSize, 1.0 / inverseThreshold);

          // Pointer condition for visibility
          if (pointerOffset == null) {
            return const SizedBox.shrink();
          }

          final ColorScheme colorScheme = Theme.of(context).colorScheme;
          final bool isDark = Theme.of(context).brightness == Brightness.dark;

          final Color baseColor = isHit
              ? colorScheme.error.withValues(alpha: 0.6)
              : colorScheme.onSurface.withValues(alpha: 0.1);

          final double blur =
              isHit ? 0.0 : (progress * _InteractionPhysics.kMaxBlur);
          final double borderRadius =
              isHit ? 0.0 : _InteractionPhysics.kBaseRadius;

          final isVertical = zone.axis == Axis.vertical;
          final alignment = zone.alignment;

          // Transition logic:
          // If progress is very low, we show the Idle Handle.
          // As progress grows, we morph into the stretching glass bar.
          // Handle is active for progress < 0.1. Bar takes over after.
          final double handleOpacity = (1.0 - (progress * 5.0)).clamp(0.0, 1.0);
          final double barOpacity = (progress * 5.0).clamp(0.0, 1.0);

          // Calculate normalized pointer position for the radial gradient
          // and pinch. We default to center (0,0) if no pointer is present.
          Offset gradientAlignment = Offset.zero;
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final local = renderBox.globalToLocal(pointerOffset);
            gradientAlignment = Offset(
              ((local.dx / renderBox.size.width) * 2 - 1).clamp(-1.0, 1.0),
              ((local.dy / renderBox.size.height) * 2 - 1).clamp(-1.0, 1.0),
            );
          }

          return AnimatedContainer(
            duration: _InteractionPhysics.kInteractionDuration,
            curve: Curves.easeOutCubic,
            child: Stack(
              alignment: alignment, // Align children to the relevant edge
              children: [
                // The Idle Handle (The Invitation)
                if (!isHit)
                  Opacity(
                    opacity: handleOpacity,
                    child: Center(
                      child: _IdleHandle(
                        isVertical: isVertical,
                        alignment: alignment,
                        gradientAlignment: gradientAlignment,
                      ),
                    ),
                  ),

                // The Stretching Glass Bar (The Void)
                Opacity(
                  opacity: isHit ? 1.0 : barOpacity,
                  child: ClipRRect(
                    borderRadius:
                        _calculateBorderRadius(alignment, borderRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                      child: AnimatedContainer(
                        duration: _InteractionPhysics.kInteractionDuration,
                        curve: Curves.easeOutCubic,
                        width: isVertical
                            ? ((1.0 / inverseThreshold) *
                                (isHit ? 1.0 : progress))
                            : null,
                        height: !isVertical
                            ? ((1.0 / inverseThreshold) *
                                (isHit ? 1.0 : progress))
                            : null,
                        decoration: BoxDecoration(
                          color: baseColor,
                          gradient: isHit
                              ? RadialGradient(
                                  center: Alignment(
                                    gradientAlignment.dx,
                                    gradientAlignment.dy,
                                  ),
                                  radius: 1.2,
                                  colors: [
                                    colorScheme.error.withValues(alpha: 0.8),
                                    colorScheme.error.withValues(alpha: 0.5),
                                  ],
                                )
                              : null,
                          border: Border.all(
                            color: colorScheme.onSurface
                                .withValues(alpha: isDark ? 0.2 : 0.1),
                            width: 0.5,
                          ), // Border.all
                        ), // BoxDecoration
                      ), // AnimatedContainer
                    ), // BackdropFilter
                  ), // ClipRRect
                ), // Opacity,

                // Stage 3: Dynamic Stretching Icon (The Bridge)
                // This icon appears as you stretch and stays at the "tip".
                if (progress > 0.05)
                  Positioned(
                    left: isVertical
                        ? (alignment == Alignment.centerLeft
                            ? ((1.0 / inverseThreshold) * progress - 24)
                            : null)
                        : null,
                    right: isVertical
                        ? (alignment == Alignment.centerRight
                            ? ((1.0 / inverseThreshold) * progress - 24)
                            : null)
                        : null,
                    top: !isVertical
                        ? (alignment == Alignment.topCenter
                            ? ((1.0 / inverseThreshold) * progress - 24)
                            : null)
                        : null,
                    bottom: !isVertical
                        ? (alignment == Alignment.bottomCenter
                            ? ((1.0 / inverseThreshold) * progress - 24)
                            : null)
                        : null,
                    child: Transform.translate(
                      offset: Offset(
                        gradientAlignment.dx * 16,
                        gradientAlignment.dy * 16,
                      ),
                      child: Opacity(
                        opacity: (progress * 2).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.5 + (progress * 0.5),
                          child: Icon(
                            Icons.close_rounded,
                            color: isHit ? Colors.white : colorScheme.onSurface,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );

  BorderRadius _calculateBorderRadius(
    final Alignment alignment,
    final double radius,
  ) {
    if (radius <= 0) return BorderRadius.zero;

    return BorderRadius.only(
      topLeft: (alignment == Alignment.bottomCenter ||
              alignment == Alignment.centerRight)
          ? Radius.circular(radius)
          : Radius.zero,
      topRight: (alignment == Alignment.bottomCenter ||
              alignment == Alignment.centerLeft)
          ? Radius.circular(radius)
          : Radius.zero,
      bottomLeft: (alignment == Alignment.topCenter ||
              alignment == Alignment.centerRight)
          ? Radius.circular(radius)
          : Radius.zero,
      bottomRight: (alignment == Alignment.topCenter ||
              alignment == Alignment.centerLeft)
          ? Radius.circular(radius)
          : Radius.zero,
    );
  }
}

class _IdleHandle extends StatefulWidget {
  const _IdleHandle({
    required this.isVertical,
    required this.alignment,
    required this.gradientAlignment,
  });
  final bool isVertical;
  final Alignment alignment;
  final Offset gradientAlignment;

  @override
  State<_IdleHandle> createState() => _IdleHandleState();
}

class _IdleHandleState extends State<_IdleHandle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final isVertical = widget.isVertical;
    final alignment = widget.alignment;

    // Determine corner radii based on edge alignment
    final borderRadius = BorderRadius.only(
      topLeft: (alignment == Alignment.centerRight ||
              alignment == Alignment.bottomCenter)
          ? const Radius.circular(20)
          : Radius.zero,
      topRight: (alignment == Alignment.centerLeft ||
              alignment == Alignment.bottomCenter)
          ? const Radius.circular(20)
          : Radius.zero,
      bottomLeft: (alignment == Alignment.centerRight ||
              alignment == Alignment.topCenter)
          ? const Radius.circular(20)
          : Radius.zero,
      bottomRight: (alignment == Alignment.centerLeft ||
              alignment == Alignment.topCenter)
          ? const Radius.circular(20)
          : Radius.zero,
    );

    final themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;

    return FadeTransition(
      opacity: Tween(begin: 0.15, end: 0.4).animate(_pulseController),
      child: Transform.translate(
        offset: Offset(
          widget.gradientAlignment.dx * 10,
          widget.gradientAlignment.dy * 10,
        ),
        child: Container(
          width: isVertical ? 24 : 60,
          height: isVertical ? 60 : 24,
          decoration: BoxDecoration(
            color: colorScheme.onSurface,
            borderRadius: borderRadius,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.close_rounded,
            size: 16,
            color: colorScheme.surface,
          ),
        ),
      ),
    );
  }
}

/// A subtle background gradient that appears when the pointer is approaching
/// a dismissal zone, providing a soft "proximity hint" before engagement.
class _EdgeAura extends StatelessWidget {
  const _EdgeAura({
    required this.zone,
    required this.dragPosition,
    required this.screenSize,
    required this.threshold,
  });

  final InteractionZone zone;
  final ValueNotifier<OffsetPair?> dragPosition;
  final Size screenSize;
  final double threshold;

  @override
  Widget build(final BuildContext context) =>
      ValueListenableBuilder<OffsetPair?>(
        valueListenable: dragPosition,
        builder: (final context, final dragPair, final child) {
          final pointerOffset = dragPair?.global;
          if (pointerOffset == null) {
            return const SizedBox.shrink();
          }

          // Calculate "aura" progress based on a larger distance
          // (e.g., 3x threshold)
          final auraThreshold = threshold * 3.0;
          final progress = zone.calculateProgress(
            pointerOffset,
            screenSize,
            1.0 / auraThreshold,
          );

          if (progress <= 0) {
            return const SizedBox.shrink();
          }

          // Aura logic: subtle gradient at the edge
          final isVertical = zone.axis == Axis.vertical;
          final alignment = zone.alignment;

          final themeData = Theme.of(context);
          final colorScheme = themeData.colorScheme;

          return Positioned.fill(
            child: AnimatedOpacity(
              duration: _InteractionPhysics.kAuraDuration,
              opacity: (progress * 0.15).clamp(0.0, 0.15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: isVertical
                        ? (alignment == Alignment.centerLeft
                            ? Alignment.centerLeft
                            : Alignment.centerRight)
                        : (alignment == Alignment.topCenter
                            ? Alignment.topCenter
                            : Alignment.bottomCenter),
                    end: isVertical
                        ? (alignment == Alignment.centerLeft
                            ? Alignment.centerRight
                            : Alignment.centerLeft)
                        : (alignment == Alignment.topCenter
                            ? Alignment.bottomCenter
                            : Alignment.topCenter),
                    stops: const [0.0, 0.2],
                    colors: [
                      colorScheme.onSurface,
                      colorScheme.onSurface.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

/// Internal physics constants for controlling the "feel" of interactions.
abstract final class _InteractionPhysics {
  /// The duration of the proximity aura fade-in/out.
  static const Duration kAuraDuration = Duration(milliseconds: 300);

  /// The duration of the visual stretching/engagement transitions.
  static const Duration kInteractionDuration = Duration(milliseconds: 150);

  /// The standard blur factor for the dismissal background.
  static const double kMaxBlur = 15.0;

  /// The standard border radius for the floating elements.
  static const double kBaseRadius = 24.0;
}
