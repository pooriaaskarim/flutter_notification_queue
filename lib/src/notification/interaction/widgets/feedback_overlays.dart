part of '../../notification.dart';

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

    final cardContent = ColorFiltered(
      colorFilter: passedThreshold
          ? ColorUtils.grayscaleFilter
          : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: passedThreshold
            ? ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: sinkingBlur,
                  sigmaY: sinkingBlur,
                ),
                child: child,
              )
            : child,
      ),
    );

    return Transform.translate(
      offset: correction,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: baseScale * sinkingScale,
              alignment: lockedZone?.alignment ?? Alignment.center,
              child: cardContent,
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

  static Path? _cachedPath;
  static Size? _cachedSize;

  @override
  void paint(final Canvas canvas, final Size size) {
    const radius = Radius.circular(12);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (_cachedPath == null || _cachedSize != size) {
      _cachedSize = size;
      _cachedPath = _buildDashedPath(size, radius);
    }

    canvas.drawPath(_cachedPath!, paint);
  }

  Path _buildDashedPath(final Size size, final Radius radius) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
      radius,
    );
    final sourcePath = Path()..addRRect(rrect);
    final dashedPath = Path();
    const dashWidth = 6.0;
    const dashSpace = 4.0;

    final metrics = sourcePath.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0, metric.length);
        dashedPath.addPath(
          metric.extractPath(distance, end as double),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    return dashedPath;
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

    final Color shadowColor = Colors.black.withValues(alpha: 0.25);
    final double shadowBlur = passedThreshold ? 4.0 : 20.0;
    final double shadowSpread = passedThreshold ? 0.0 : 4.0;
    final Offset shadowOffset =
        passedThreshold ? const Offset(0, 2) : const Offset(0, 8);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: widgetSize.width,
          height: widgetSize.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: shadowBlur,
                spreadRadius: shadowSpread,
                offset: shadowOffset,
              ),
              BoxShadow(
                color: glowColor.withValues(alpha: engaged ? 0.45 : 0.0),
                blurRadius: 24,
                spreadRadius: glowSpread,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ColorFiltered(
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
