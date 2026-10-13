import 'package:flutter/material.dart';

/// A draggable split handle placed between studio panels.
///
/// Features:
/// - 8px interactive hit-test target with 1px neutral resting divider.
/// - Vibrant primary highlight glow and centered grip notch on hover/drag.
/// - Double-click callback for quick-collapse or reset.
class PaneSplitter extends StatefulWidget {
  const PaneSplitter({
    required this.onDragDelta,
    this.onDoubleClick,
    this.tooltip,
    super.key,
  });

  /// Invoked when the user drags horizontally, passing the delta in pixels.
  final ValueChanged<double> onDragDelta;

  /// Optional action triggered on double-click (e.g. collapse or reset).
  final VoidCallback? onDoubleClick;

  /// Tooltip displayed on hover.
  final String? tooltip;

  @override
  State<PaneSplitter> createState() => _PaneSplitterState();
}

class _PaneSplitterState extends State<PaneSplitter> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = _isHovered || _isDragging;

    final splitter = MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (final _) => setState(() => _isHovered = true),
      onExit: (final _) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: widget.onDoubleClick,
        onHorizontalDragStart: (final _) => setState(() => _isDragging = true),
        onHorizontalDragUpdate: (final details) {
          widget.onDragDelta(details.delta.dx);
        },
        onHorizontalDragEnd: (final _) => setState(() => _isDragging = false),
        onHorizontalDragCancel: () => setState(() => _isDragging = false),
        child: SizedBox(
          width: 8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Divider line
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: isActive ? 2.5 : 1.0,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.08),
              ),
              // Center grip notch affordance on hover/drag
              if (isActive)
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final tooltip = widget.tooltip;
    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 600),
        child: splitter,
      );
    }

    return splitter;
  }
}

/// A compact vertical dock rail displayed when a secondary panel is collapsed.
///
/// Clicking or dragging restores the panel to its active position.
class CollapsedPaneRail extends StatefulWidget {
  const CollapsedPaneRail({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onExpand,
    this.onDragExpand,
    super.key,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onExpand;
  final ValueChanged<double>? onDragExpand;

  @override
  State<CollapsedPaneRail> createState() => _CollapsedPaneRailState();
}

class _CollapsedPaneRailState extends State<CollapsedPaneRail> {
  bool _isHovered = false;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (final _) => setState(() => _isHovered = true),
      onExit: (final _) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onExpand,
        onHorizontalDragUpdate: (final details) {
          if (widget.onDragExpand != null) {
            widget.onDragExpand!(details.delta.dx);
          } else {
            widget.onExpand();
          }
        },
        child: Tooltip(
          message: '${widget.tooltip} (Click or Drag)',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            decoration: BoxDecoration(
              color: _isHovered
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              border: Border(
                left: BorderSide(
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                right: BorderSide(
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Icon(
                  widget.icon,
                  size: 15,
                  color: _isHovered
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Center(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: _isHovered
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.unfold_more_rounded,
                  size: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
