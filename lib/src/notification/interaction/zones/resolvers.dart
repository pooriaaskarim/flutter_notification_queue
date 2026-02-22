part of '../../notification.dart';

// ─── Drop Zone Resolvers ───────────────────────────────────────────────────

/// Derives a [PositionDropZone] for each configured relocation target.
///
/// Each target position gets its own zone anchored at its screen location.
/// The current queue position is excluded — you cannot relocate to where you
/// already are.
List<PositionDropZone> _zonesFromPositions(
  final Set<QueuePosition> targetPositions,
  final QueuePosition currentPosition,
) =>
    targetPositions
        .where((final p) => p != currentPosition)
        .map((final p) => PositionDropZone(position: p))
        .toList();

/// Resolves the active [EdgeDropZone]s for a [Dismiss] behavior.
List<EdgeDropZone> _edgesFromDismissZone(
  final DismissZone zones,
  final QueuePosition currentPosition,
) {
  if (zones == DismissZone.sideEdges) {
    return const [LeftEdgeDropZone(), RightEdgeDropZone()];
  }

  return switch (currentPosition) {
    QueuePosition.topLeft => const [
        TopEdgeDropZone(isNatural: true),
        LeftEdgeDropZone(isNatural: true),
      ],
    QueuePosition.topCenter => const [TopEdgeDropZone(isNatural: true)],
    QueuePosition.topRight => const [
        TopEdgeDropZone(isNatural: true),
        RightEdgeDropZone(isNatural: true),
      ],
    QueuePosition.bottomLeft => const [
        BottomEdgeDropZone(isNatural: true),
        LeftEdgeDropZone(isNatural: true),
      ],
    QueuePosition.bottomCenter => const [BottomEdgeDropZone(isNatural: true)],
    QueuePosition.bottomRight => const [
        BottomEdgeDropZone(isNatural: true),
        RightEdgeDropZone(isNatural: true),
      ],
    QueuePosition.centerLeft => const [LeftEdgeDropZone(isNatural: true)],
    QueuePosition.centerRight => const [RightEdgeDropZone(isNatural: true)],
  };
}
