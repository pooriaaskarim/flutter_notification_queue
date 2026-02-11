part of 'overlay_manager.dart';

class OverlayEntryData {
  OverlayEntryData({
    required this.builder,
    required this.position,
    this.priority = 0,
    this.entryDuration = const Duration(milliseconds: 300),
    this.exitDuration = const Duration(milliseconds: 200),
    this.entryCurve = Curves.easeInOut,
    this.exitCurve = Curves.easeOut,
    this.maintainState = false,
    this.onShow,
    this.onHide,
  });

  final WidgetBuilder builder; // Builds the overlay_manager content
  final OverlayPosition position;
  final int priority; // Z-index for stacking (higher = front)
  final Duration? entryDuration, exitDuration; // For animations
  final Curve entryCurve, exitCurve;
  final bool maintainState; // Preserve state when hidden
  final VoidCallback? onShow, onHide;
  GlobalKey? stateKey;
}
