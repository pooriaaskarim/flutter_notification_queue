part of '../../notification.dart';

// ─── Drop Zone Resolvers ───────────────────────────────────────────────────

/// Derives the minimal set of [EdgeDropZone]s required to monitor all screen
/// directions toward the given [targetPositions].
List<EdgeDropZone> _edgesFromPositions(
  final Set<QueuePosition> targetPositions,
  final QueuePosition currentPosition,
) {
  final naturalTypes = _naturalEdgeTypesOf(currentPosition);

  final Set<Type> requiredTypes = {};
  for (final position in targetPositions) {
    requiredTypes.addAll(_edgeTypesLeadingTo(position));
  }

  return requiredTypes
      .map(
        (final type) =>
            _createEdge(type, isNatural: naturalTypes.contains(type)),
      )
      .toList();
}

/// Returns the concrete types of [EdgeDropZone]s a drag must cross to reaches
/// the given [position].
Set<Type> _edgeTypesLeadingTo(final QueuePosition position) =>
    switch (position) {
      QueuePosition.topLeft => {TopEdgeDropZone, LeftEdgeDropZone},
      QueuePosition.topCenter => {TopEdgeDropZone},
      QueuePosition.topRight => {TopEdgeDropZone, RightEdgeDropZone},
      QueuePosition.centerLeft => {LeftEdgeDropZone},
      QueuePosition.centerRight => {RightEdgeDropZone},
      QueuePosition.bottomLeft => {BottomEdgeDropZone, LeftEdgeDropZone},
      QueuePosition.bottomCenter => {BottomEdgeDropZone},
      QueuePosition.bottomRight => {BottomEdgeDropZone, RightEdgeDropZone},
    };

/// Returns the types of edges that [position] naturally sits against.
Set<Type> _naturalEdgeTypesOf(final QueuePosition position) =>
    switch (position) {
      QueuePosition.topLeft => {TopEdgeDropZone, LeftEdgeDropZone},
      QueuePosition.topCenter => {TopEdgeDropZone},
      QueuePosition.topRight => {TopEdgeDropZone, RightEdgeDropZone},
      QueuePosition.centerLeft => {LeftEdgeDropZone},
      QueuePosition.centerRight => {RightEdgeDropZone},
      QueuePosition.bottomLeft => {BottomEdgeDropZone, LeftEdgeDropZone},
      QueuePosition.bottomCenter => {BottomEdgeDropZone},
      QueuePosition.bottomRight => {BottomEdgeDropZone, RightEdgeDropZone},
    };

EdgeDropZone _createEdge(
  final Type type, {
  required final bool isNatural,
}) =>
    switch (type) {
      const (LeftEdgeDropZone) => LeftEdgeDropZone(isNatural: isNatural),
      const (RightEdgeDropZone) => RightEdgeDropZone(isNatural: isNatural),
      const (TopEdgeDropZone) => TopEdgeDropZone(isNatural: isNatural),
      const (BottomEdgeDropZone) => BottomEdgeDropZone(isNatural: isNatural),
      _ => throw ArgumentError('Unknown EdgeDropZone type: $type'),
    };

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
