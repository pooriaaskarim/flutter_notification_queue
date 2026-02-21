part of '../notification.dart';

/// The screen edge an interaction zone is attached to.
enum InteractionZoneEdge { left, right, top, bottom }

/// Concrete zones where interactions (dismissal or relocation) can occur based
/// on edge-detection.
sealed class InteractionZone {
  const InteractionZone({this.isNatural = false});

  /// Whether this zone matches the "natural" interaction direction.
  final bool isNatural;

  /// The screen edge this zone is attached to.
  InteractionZoneEdge get edge;

  /// The main axis of the zone (vertical bar vs horizontal bar).
  Axis get axis =>
      (edge == InteractionZoneEdge.left || edge == InteractionZoneEdge.right)
          ? Axis.vertical
          : Axis.horizontal;

  /// The alignment of the zone along the edge.
  Alignment get alignment => switch (edge) {
        InteractionZoneEdge.left => Alignment.centerLeft,
        InteractionZoneEdge.right => Alignment.centerRight,
        InteractionZoneEdge.top => Alignment.topCenter,
        InteractionZoneEdge.bottom => Alignment.bottomCenter,
      };

  /// Returns 0.0 to 1.0 based on how close the pointer is to the edge.
  double calculateProgress(
    final Offset pointer,
    final Size screenSize,
    final double inverseThreshold,
  );

  /// The interaction state for a given pointer position.
  ///
  /// * **Hit**: The pointer is within the physical threshold of the zone.
  /// * **Natural-Safe**: For "home-edge" zones, we require a deeper pull (70%)
  ///   to avoid accidental triggers during micro-drags.
  bool isHit(
    final Offset pointer,
    final Size screenSize,
    final double threshold,
  ) {
    // Optimization: Use inverse multiplication
    final progress = calculateProgress(pointer, screenSize, 1.0 / threshold);
    return _ThresholdPolicies.evaluate(progress, isNatural);
  }

  /// Generates the list of active zones for a given configuration.
  static List<InteractionZone> generate(
    final DismissZone type,
    final QueuePosition position,
  ) {
    if (type == DismissZone.sideEdges) {
      return [
        const LeftInteractionZone(),
        const RightInteractionZone(),
      ];
    }

    // Natural Direction
    return switch (position) {
      QueuePosition.topLeft => [
          const TopInteractionZone(isNatural: true),
          const LeftInteractionZone(isNatural: true),
        ],
      QueuePosition.topCenter => [
          const TopInteractionZone(isNatural: true),
        ],
      QueuePosition.topRight => [
          const TopInteractionZone(isNatural: true),
          const RightInteractionZone(isNatural: true),
        ],
      QueuePosition.bottomLeft => [
          const BottomInteractionZone(isNatural: true),
          const LeftInteractionZone(isNatural: true),
        ],
      QueuePosition.bottomCenter => [
          const BottomInteractionZone(isNatural: true),
        ],
      QueuePosition.bottomRight => [
          const BottomInteractionZone(isNatural: true),
          const RightInteractionZone(isNatural: true),
        ],
      QueuePosition.centerLeft => [
          const LeftInteractionZone(isNatural: true),
        ],
      QueuePosition.centerRight => [
          const RightInteractionZone(isNatural: true),
        ],
    };
  }
}

class LeftInteractionZone extends InteractionZone {
  const LeftInteractionZone({super.isNatural});

  @override
  InteractionZoneEdge get edge => InteractionZoneEdge.left;

  @override
  double calculateProgress(
    final Offset pointer,
    final Size screenSize,
    final double inverseThreshold,
  ) =>
      (pointer.dx < screenSize.width * 0.5)
          ? (1.0 - (pointer.dx * inverseThreshold)).clamp(0.0, 1.0)
          : 0.0;
}

class RightInteractionZone extends InteractionZone {
  const RightInteractionZone({super.isNatural});

  @override
  InteractionZoneEdge get edge => InteractionZoneEdge.right;

  @override
  double calculateProgress(
    final Offset pointer,
    final Size screenSize,
    final double inverseThreshold,
  ) =>
      (pointer.dx > screenSize.width * 0.5)
          ? (1.0 - ((screenSize.width - pointer.dx) * inverseThreshold))
              .clamp(0.0, 1.0)
          : 0.0;
}

class TopInteractionZone extends InteractionZone {
  const TopInteractionZone({super.isNatural});

  @override
  InteractionZoneEdge get edge => InteractionZoneEdge.top;

  @override
  double calculateProgress(
    final Offset pointer,
    final Size screenSize,
    final double inverseThreshold,
  ) =>
      (pointer.dy < screenSize.height * 0.5)
          ? (1.0 - (pointer.dy * inverseThreshold)).clamp(0.0, 1.0)
          : 0.0;
}

class BottomInteractionZone extends InteractionZone {
  const BottomInteractionZone({super.isNatural});

  @override
  InteractionZoneEdge get edge => InteractionZoneEdge.bottom;

  @override
  double calculateProgress(
    final Offset pointer,
    final Size screenSize,
    final double inverseThreshold,
  ) =>
      (pointer.dy > screenSize.height * 0.5)
          ? (1.0 - ((screenSize.height - pointer.dy) * inverseThreshold))
              .clamp(0.0, 1.0)
          : 0.0;
}

/// Internal helper defining the hit-detection logic for interaction zones.
abstract final class _ThresholdPolicies {
  const _ThresholdPolicies._();

  /// Evaluates whether the current [progress] constitutes a "Hit" based on
  /// the [isNatural] policy (hysteresis vs immediate).
  static bool evaluate(final double progress, final bool isNatural) {
    if (isNatural) {
      // Natural (home-edge) zones require a deeper pull to prevent
      // immediate trigger. progress >= 0.7 means within 30% of
      // the threshold from the edge (e.g., 15px for a 50px threshold).
      return progress >= 0.7;
    }
    // For other edges, any deliberate entry into the threshold counts.
    return progress > 0.01;
  }
}
