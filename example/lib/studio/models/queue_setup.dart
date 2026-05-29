import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show BorderRadius, EdgeInsets;
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

/// The immutable setup for a single [NotificationQueue].
///
/// Does **not** include `position` — that's the map key in `StudioSetup`.
/// Extends [Equatable] for free change detection.
class QueueSetup extends Equatable {
  const QueueSetup({
    this.styleType = FilledQueueStyle,
    this.opacity = 0.7,
    this.elevation = 3.0,
    this.borderRadius = 8.0,
    this.transitionType = SlideTransitionStrategy,
    this.maxStackSize = 3,
    this.spacing = 4.0,
    this.verticalMargin = 8.0,
    this.horizontalMargin = 36.0,
    this.dragBehaviorType = Dismiss,
    this.dragDismissZone = DismissZone.sideEdges,
    this.longPressBehaviorType = Disabled,
    this.longPressDismissZone = DismissZone.sideEdges,
    this.relocateTargets = const {},
    this.closeButtonBehaviorType = AlwaysVisible,
    this.tapBehaviorType = TapToDismiss,
  });

  // ── Style ──
  final Type styleType;
  final double opacity;
  final double elevation;
  final double borderRadius;

  // ── Animation ──
  final Type transitionType;

  // ── Stack ──
  final int maxStackSize;
  final double spacing;
  final double verticalMargin;
  final double horizontalMargin;

  // ── Gestures ──
  final Type dragBehaviorType;
  final DismissZone dragDismissZone;
  final Type longPressBehaviorType;
  final DismissZone longPressDismissZone;
  final Set<QueuePosition> relocateTargets;
  final Type closeButtonBehaviorType;

  // ── Tap ──
  final Type tapBehaviorType;

  /// Whether this queue is in an invalid relocation state (Relocate behavior
  /// selected but no targets chosen). Empty targets cause library crashes.
  bool get hasRelocationError =>
      (dragBehaviorType == Relocate ||
          longPressBehaviorType == Relocate ||
          dragBehaviorType == ReorderAndRelocate ||
          longPressBehaviorType == ReorderAndRelocate) &&
      relocateTargets.isEmpty;

  QueueSetup copyWith({
    final Type? styleType,
    final double? opacity,
    final double? elevation,
    final double? borderRadius,
    final Type? transitionType,
    final int? maxStackSize,
    final double? spacing,
    final double? verticalMargin,
    final double? horizontalMargin,
    final Type? dragBehaviorType,
    final DismissZone? dragDismissZone,
    final Type? longPressBehaviorType,
    final DismissZone? longPressDismissZone,
    final Set<QueuePosition>? relocateTargets,
    final Type? closeButtonBehaviorType,
    final Type? tapBehaviorType,
  }) =>
      QueueSetup(
        styleType: styleType ?? this.styleType,
        opacity: opacity ?? this.opacity,
        elevation: elevation ?? this.elevation,
        borderRadius: borderRadius ?? this.borderRadius,
        transitionType: transitionType ?? this.transitionType,
        maxStackSize: maxStackSize ?? this.maxStackSize,
        spacing: spacing ?? this.spacing,
        verticalMargin: verticalMargin ?? this.verticalMargin,
        horizontalMargin: horizontalMargin ?? this.horizontalMargin,
        dragBehaviorType: dragBehaviorType ?? this.dragBehaviorType,
        dragDismissZone: dragDismissZone ?? this.dragDismissZone,
        longPressBehaviorType:
            longPressBehaviorType ?? this.longPressBehaviorType,
        longPressDismissZone: longPressDismissZone ?? this.longPressDismissZone,
        relocateTargets: relocateTargets ?? this.relocateTargets,
        closeButtonBehaviorType:
            closeButtonBehaviorType ?? this.closeButtonBehaviorType,
        tapBehaviorType: tapBehaviorType ?? this.tapBehaviorType,
      );

  // ── Library Mapping Helpers ──

  /// Builds the [QueueStyle] for this setup.
  QueueStyle toQueueStyle() {
    if (styleType == FlatQueueStyle) {
      return FlatQueueStyle(
        opacity: opacity,
        elevation: elevation,
        borderRadius: _borderRadius,
      );
    }
    if (styleType == OutlinedQueueStyle) {
      return OutlinedQueueStyle(
        opacity: opacity,
        elevation: elevation,
        borderRadius: _borderRadius,
      );
    }
    return FilledQueueStyle(
      opacity: opacity,
      elevation: elevation,
      borderRadius: _borderRadius,
    );
  }

  /// Builds the [NotificationTransition] for this setup.
  NotificationTransition toTransition() {
    if (transitionType == FadeTransitionStrategy) {
      return const FadeTransitionStrategy();
    }
    if (transitionType == ScaleTransitionStrategy) {
      return const ScaleTransitionStrategy();
    }
    return const SlideTransitionStrategy();
  }

  /// Builds the [DragBehavior] from [dragBehaviorType].
  DragBehavior toDragBehavior(final QueuePosition position) {
    if (dragBehaviorType == Dismiss) {
      return Dismiss(zones: dragDismissZone);
    }
    if (dragBehaviorType == Relocate) {
      return relocateTargets.isEmpty
          ? const Disabled()
          : Relocate.to(relocateTargets);
    }
    if (dragBehaviorType == ReorderAndRelocate) {
      return relocateTargets.isEmpty
          ? const Disabled()
          : ReorderAndRelocate.to(positions: relocateTargets);
    }
    if (dragBehaviorType == Reorder) {
      return const Reorder();
    }
    return const Disabled();
  }

  /// Builds the [LongPressDragBehavior] from [longPressBehaviorType].
  LongPressDragBehavior toLongPressBehavior(final QueuePosition position) {
    if (longPressBehaviorType == Dismiss) {
      return Dismiss(zones: longPressDismissZone);
    }
    if (longPressBehaviorType == Relocate) {
      return relocateTargets.isEmpty
          ? const Disabled()
          : Relocate.to(relocateTargets);
    }
    if (longPressBehaviorType == ReorderAndRelocate) {
      return relocateTargets.isEmpty
          ? const Disabled()
          : ReorderAndRelocate.to(positions: relocateTargets);
    }
    if (longPressBehaviorType == Reorder) {
      return const Reorder();
    }
    return const Disabled();
  }

  /// Builds the [QueueCloseButtonBehavior].
  QueueCloseButtonBehavior toCloseButtonBehavior() {
    if (closeButtonBehaviorType == VisibleOnHover) {
      return const VisibleOnHover();
    }
    if (closeButtonBehaviorType == Hidden) {
      return const Hidden();
    }
    return const AlwaysVisible();
  }

  /// Builds the [TapBehavior] from [tapBehaviorType].
  TapBehavior toTapBehavior() {
    if (tapBehaviorType == TapToExpand) {
      return const TapToExpand();
    }
    if (tapBehaviorType == TapToAct) {
      return TapToAct(
        onTap: () => debugPrint('[Studio] TapToAct fired'),
      );
    }
    if (tapBehaviorType == TapDisabled) {
      return const TapDisabled();
    }
    return const TapToDismiss();
  }

  /// Builds a [NotificationQueue] at the given [position].
  NotificationQueue toNotificationQueue(final QueuePosition position) =>
      NotificationQueue.defaultQueue(
        position: position,
        style: toQueueStyle(),
        transition: toTransition(),
        maxStackSize: maxStackSize,
        spacing: spacing,
        margin: EdgeInsets.symmetric(
          vertical: verticalMargin,
          horizontal: horizontalMargin,
        ),
        dragBehavior: toDragBehavior(position),
        longPressDragBehavior: toLongPressBehavior(position),
        closeButtonBehavior: toCloseButtonBehavior(),
        tapBehavior: toTapBehavior(),
      );

  BorderRadius get _borderRadius => BorderRadius.circular(borderRadius);

  @override
  List<Object?> get props => [
        styleType,
        opacity,
        elevation,
        borderRadius,
        transitionType,
        maxStackSize,
        spacing,
        verticalMargin,
        horizontalMargin,
        dragBehaviorType,
        dragDismissZone,
        longPressBehaviorType,
        longPressDismissZone,
        relocateTargets,
        closeButtonBehaviorType,
        tapBehaviorType,
      ];
}
