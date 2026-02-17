part of '../../notification.dart';

/// The screen edge a dismissal zone is attached to.
enum DismissalZoneEdge { left, right, top, bottom }

/// Concrete zones where dismissal can occur.
sealed class DismissalZone {
  const DismissalZone({this.isNatural = false});

  /// Whether this zone matches the "natural" dismissal direction.
  final bool isNatural;

  /// The screen edge this zone is attached to.
  DismissalZoneEdge get edge;

  /// The main axis of the zone (vertical bar vs horizontal bar).
  Axis get axis =>
      (edge == DismissalZoneEdge.left || edge == DismissalZoneEdge.right)
          ? Axis.vertical
          : Axis.horizontal;

  /// The alignment of the zone along the edge.
  Alignment get alignment => switch (edge) {
        DismissalZoneEdge.left => Alignment.centerLeft,
        DismissalZoneEdge.right => Alignment.centerRight,
        DismissalZoneEdge.top => Alignment.topCenter,
        DismissalZoneEdge.bottom => Alignment.bottomCenter,
      };

  /// Returns 0.0 to 1.0 based on how close the pointer is to the edge.
  double calculateProgress(
    final Offset pointer,
    final Size screenSize,
    final double threshold,
  );

  /// Returns whether a pointer position is considered "in" this zone.
  bool isHit(
    final Offset pointer,
    final Size screenSize,
    final double threshold,
  ) {
    final progress = calculateProgress(pointer, screenSize, threshold);
    if (isNatural) {
      // Natural (home-edge) zones require a deeper pull to prevent
      // immediate trigger. progress >= 0.7 means within 30% of
      // the threshold from the edge (e.g., 15px for a 50px threshold).
      return progress >= 0.7;
    }
    // For other edges, any deliberate entry into the threshold counts.
    return progress > 0.01;
  }

  /// Generates the list of active zones for a given configuration.
  static List<DismissalZone> generate(
    final DismissZone type,
    final QueuePosition position,
  ) {
    if (type == DismissZone.sideEdges) {
      return [
        const LeftDismissalZone(),
        const RightDismissalZone(),
      ];
    }

    // Natural Direction
    return switch (position) {
      QueuePosition.topLeft => [
          const TopDismissalZone(isNatural: true),
          const LeftDismissalZone(isNatural: true),
        ],
      QueuePosition.topCenter => [
          const TopDismissalZone(isNatural: true),
        ],
      QueuePosition.topRight => [
          const TopDismissalZone(isNatural: true),
          const RightDismissalZone(isNatural: true),
        ],
      QueuePosition.bottomLeft => [
          const BottomDismissalZone(isNatural: true),
          const LeftDismissalZone(isNatural: true),
        ],
      QueuePosition.bottomCenter => [
          const BottomDismissalZone(isNatural: true),
        ],
      QueuePosition.bottomRight => [
          const BottomDismissalZone(isNatural: true),
          const RightDismissalZone(isNatural: true),
        ],
      QueuePosition.centerLeft => [
          const LeftDismissalZone(isNatural: true),
        ],
      QueuePosition.centerRight => [
          const RightDismissalZone(isNatural: true),
        ],
    };
  }
}

class LeftDismissalZone extends DismissalZone {
  const LeftDismissalZone({super.isNatural});

  @override
  DismissalZoneEdge get edge => DismissalZoneEdge.left;

  @override
  double calculateProgress(
    final Offset pointer,
    final Size screenSize,
    final double threshold,
  ) =>
      (pointer.dx < screenSize.width * 0.5)
          ? (1.0 - (pointer.dx / threshold)).clamp(0.0, 1.0)
          : 0.0;
}

class RightDismissalZone extends DismissalZone {
  const RightDismissalZone({super.isNatural});

  @override
  DismissalZoneEdge get edge => DismissalZoneEdge.right;

  @override
  double calculateProgress(
    final Offset pointer,
    final Size screenSize,
    final double threshold,
  ) =>
      (pointer.dx > screenSize.width * 0.5)
          ? (1.0 - ((screenSize.width - pointer.dx) / threshold))
              .clamp(0.0, 1.0)
          : 0.0;
}

class TopDismissalZone extends DismissalZone {
  const TopDismissalZone({super.isNatural});

  @override
  DismissalZoneEdge get edge => DismissalZoneEdge.top;

  @override
  double calculateProgress(
    final Offset pointer,
    final Size screenSize,
    final double threshold,
  ) =>
      (pointer.dy < screenSize.height * 0.5)
          ? (1.0 - (pointer.dy / threshold)).clamp(0.0, 1.0)
          : 0.0;
}

class BottomDismissalZone extends DismissalZone {
  const BottomDismissalZone({super.isNatural});

  @override
  DismissalZoneEdge get edge => DismissalZoneEdge.bottom;

  @override
  double calculateProgress(
    final Offset pointer,
    final Size screenSize,
    final double threshold,
  ) =>
      (pointer.dy > screenSize.height * 0.5)
          ? (1.0 - ((screenSize.height - pointer.dy) / threshold))
              .clamp(0.0, 1.0)
          : 0.0;
}
