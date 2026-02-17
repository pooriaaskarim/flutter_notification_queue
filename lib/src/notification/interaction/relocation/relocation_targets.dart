part of '../../notification.dart';

class _RelocationTargets extends StatelessWidget {
  const _RelocationTargets({
    required this.onAccept,
    required this.currentPosition,
    required this.targets,
    required this.screenSize,
    required this.passedThreshold,
  });

  final void Function(QueuePosition candidatePosition) onAccept;
  final Set<QueuePosition> targets;
  final bool passedThreshold;
  final QueuePosition currentPosition;
  final Size screenSize;

  @override
  Widget build(final BuildContext context) => Stack(
        fit: StackFit.passthrough,
        children: [
          ...targets.map((final position) {
            if (position == currentPosition) {
              return const SizedBox.shrink();
            }
            return Align(
              alignment: position.alignment,
              child: DragTarget<QueuePosition>(
                hitTestBehavior: HitTestBehavior.opaque,
                onWillAcceptWithDetails: (final details) => true,
                onAcceptWithDetails: (final details) {
                  if (passedThreshold) {
                    onAccept(position);
                  }
                },
                builder: (
                  final context,
                  final candidateData,
                  final rejectedData,
                ) {
                  final isHovering = candidateData.isNotEmpty;

                  return _DropZone(
                    isDragging: true,
                    hasCandidate: isHovering,
                    willAccept: isHovering && passedThreshold,
                    alignment: position.alignment,
                    icon: Icons.move_to_inbox_rounded,
                    color: Colors.blue,
                    label: position.displayName,
                  );
                },
              ),
            );
          }),
        ],
      );
}

class _DropZone extends StatefulWidget {
  const _DropZone({
    required this.isDragging,
    required this.hasCandidate,
    required this.willAccept,
    required this.alignment,
    required this.icon,
    required this.color,
    this.label,
  });

  final bool isDragging;
  final bool hasCandidate;
  final bool willAccept;
  final AlignmentGeometry alignment;
  final IconData icon;
  final Color color;
  final String? label;

  @override
  State<_DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<_DropZone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hintController;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  double _getArrowRotation(final BuildContext context) {
    final Alignment resolved =
        widget.alignment.resolve(Directionality.of(context));

    if (resolved.y == -1.0) {
      if (resolved.x == -1.0) {
        return -3 * 3.14159 / 4;
      }
      if (resolved.x == 0.0) {
        return -3.14159 / 2;
      }
      if (resolved.x == 1.0) {
        return -3.14159 / 4;
      }
    }
    if (resolved.y == 0.0) {
      if (resolved.x == -1.0) {
        return 3.14159;
      }
      if (resolved.x == 1.0) {
        return 0.0;
      }
    }
    if (resolved.y == 1.0) {
      if (resolved.x == -1.0) {
        return 3 * 3.14159 / 4;
      }
      if (resolved.x == 0.0) {
        return 3.14159 / 2;
      }
      if (resolved.x == 1.0) {
        return 3.14159 / 4;
      }
    }
    return 0.0;
  }

  @override
  Widget build(final BuildContext context) {
    final double opacity = widget.willAccept
        ? 1.0
        : widget.hasCandidate
            ? 1.0
            : widget.isDragging
                ? 0.9
                : 0.0;

    final double scale = widget.willAccept
        ? 1.1
        : widget.hasCandidate
            ? 1.05
            : 1.0;

    final Color effectiveColor = widget.willAccept
        ? Colors.green
        : widget.hasCandidate
            ? widget.color
            : Colors.grey.withValues(alpha: 0.5);

    final Alignment resolvedAlignment =
        widget.alignment.resolve(Directionality.of(context));
    const double kBaseMargin = 24.0;
    const double kDockedMargin = 0.0;

    final EdgeInsetsGeometry margin = widget.willAccept
        ? EdgeInsets.fromLTRB(
            resolvedAlignment.x == -1.0 ? kDockedMargin : kBaseMargin,
            resolvedAlignment.y == -1.0 ? kDockedMargin : kBaseMargin,
            resolvedAlignment.x == 1.0 ? kDockedMargin : kBaseMargin,
            resolvedAlignment.y == 1.0 ? kDockedMargin : kBaseMargin,
          )
        : const EdgeInsets.all(kBaseMargin);

    final bool showHintArrow = widget.isDragging && !widget.hasCandidate;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      opacity: opacity,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        scale: scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: margin,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.hasCandidate ? 20 : 12,
              vertical: 12,
            ),
            decoration: ShapeDecoration(
              color: widget.hasCandidate
                  ? effectiveColor
                  : effectiveColor.withValues(alpha: 0.1),
              shape: const StadiumBorder(),
              shadows: [
                if (widget.hasCandidate)
                  BoxShadow(
                    color: effectiveColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showHintArrow)
                  RotationTransition(
                    turns: AlwaysStoppedAnimation(
                      _getArrowRotation(context) / (2 * 3.14159),
                    ),
                    child: FadeTransition(
                      opacity: _hintController,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.8, end: 1.2)
                            .animate(_hintController),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 24,
                          color: effectiveColor,
                        ),
                      ),
                    ),
                  )
                else
                  Icon(
                    widget.icon,
                    size: 24,
                    color: widget.hasCandidate ? Colors.white : effectiveColor,
                  ),
                if (widget.hasCandidate &&
                    !widget.willAccept &&
                    widget.label != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.label!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
