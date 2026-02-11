part of 'overlay_manager.dart';

sealed class OverlayPosition {
  const OverlayPosition();
}

final class AbsolutePosition extends OverlayPosition {
  const AbsolutePosition(this.offset);

  final Offset offset;
}

final class AlignedPosition extends OverlayPosition {
  const AlignedPosition(this.alignment);

  final AlignmentGeometry alignment;
}

final class AnchoredPosition extends OverlayPosition {
  const AnchoredPosition(
    this.anchorKey, {
    this.followerAlignment = Alignment.center,
    this.targetAlignment = Alignment.center,
  });

  final GlobalKey anchorKey;
  final Alignment followerAlignment;
  final Alignment targetAlignment;
}
