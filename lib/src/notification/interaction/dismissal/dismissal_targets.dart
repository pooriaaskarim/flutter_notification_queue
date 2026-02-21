part of '../../notification.dart';

class _DismissionTargets extends StatefulWidget {
  const _DismissionTargets({
    required this.onAccept,
    required this.screenSize,
    required this.threshold,
    required this.zones,
    required this.pointerPositionNotifier,
  });

  final void Function() onAccept;
  final double threshold;
  final Size screenSize;
  final List<DismissalZone> zones;
  final ValueNotifier<OffsetPair?> pointerPositionNotifier;

  @override
  State<_DismissionTargets> createState() => _DismissionTargetsState();
}

class _DismissionTargetsState extends State<_DismissionTargets> {
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

class _PositionedZone extends StatelessWidget {
  const _PositionedZone({
    required this.zone,
    required this.screenSize,
    required this.inverseThreshold,
    required this.dragPosition,
  });

  final DismissalZone zone;
  final Size screenSize;
  final double inverseThreshold;
  final ValueNotifier<OffsetPair?> dragPosition;

  @override
  Widget build(final BuildContext context) {
    // Calculate position based on alignment and axis
    double? left;
    double? right;
    double? top;
    double? bottom;
    double? width;
    double? height;

    if (zone.axis == Axis.vertical) {
      width = 1.0 / inverseThreshold;
      height = screenSize.height; // Assuming extent 1.0 (Rationalized)
      top = 0;
      if (zone.alignment == Alignment.centerLeft) {
        left = 0;
      } else if (zone.alignment == Alignment.centerRight) {
        right = 0;
      }
    } else {
      height = 1.0 / inverseThreshold;
      width = screenSize.width; // Assuming extent 1.0 (Rationalized)
      left = 0;
      if (zone.alignment == Alignment.topCenter) {
        top = 0;
      } else if (zone.alignment == Alignment.bottomCenter) {
        bottom = 0;
      }
    }

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      width: width,
      height: height,
      child: _DismissionZone(
        zone: zone,
        screenSize: screenSize,
        inverseThreshold: inverseThreshold,
        dragPosition: dragPosition,
      ),
    );
  }
}

class _DismissionZone extends StatelessWidget {
  const _DismissionZone({
    required this.zone,
    required this.screenSize,
    required this.inverseThreshold,
    required this.dragPosition,
  });

  final DismissalZone zone;
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

          final double blur = isHit ? 0.0 : (progress * 15.0);
          final double borderRadius = isHit ? 0.0 : 24.0;

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
          final RenderBox? rb = context.findRenderObject() as RenderBox?;
          if (rb != null) {
            final local = rb.globalToLocal(pointerOffset);
            gradientAlignment = Offset(
              ((local.dx / rb.size.width) * 2 - 1).clamp(-1.0, 1.0),
              ((local.dy / rb.size.height) * 2 - 1).clamp(-1.0, 1.0),
            );
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
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
                    borderRadius: BorderRadius.only(
                      topLeft: (alignment == Alignment.bottomCenter ||
                              alignment == Alignment.centerRight)
                          ? Radius.circular(borderRadius)
                          : Radius.zero,
                      topRight: (alignment == Alignment.bottomCenter ||
                              alignment == Alignment.centerLeft)
                          ? Radius.circular(borderRadius)
                          : Radius.zero,
                      bottomLeft: (alignment == Alignment.topCenter ||
                              alignment == Alignment.centerRight)
                          ? Radius.circular(borderRadius)
                          : Radius.zero,
                      bottomRight: (alignment == Alignment.topCenter ||
                              alignment == Alignment.centerLeft)
                          ? Radius.circular(borderRadius)
                          : Radius.zero,
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
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

class _EdgeAura extends StatelessWidget {
  const _EdgeAura({
    required this.zone,
    required this.dragPosition,
    required this.screenSize,
    required this.threshold,
  });

  final DismissalZone zone;
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
          final auraThreshold = threshold * 3;
          final progress = zone.calculateProgress(
            pointerOffset,
            screenSize,
            auraThreshold,
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
              duration: const Duration(milliseconds: 300),
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
