part of 'queue_manager.dart';

///  of [QueueManager]s, based on [AlignmentDirectional].
///
/// - [TopStartQueue]
/// - [TopCenterQueue]
/// - [TopEndQueue]
/// - [CenterStartQueue]
/// - [CenterQueue]
/// - [CenterEndQueue]
/// - [BottomStartQueue]
/// - [BottomCenterQueue]
/// - [BottomEndQueue].
///
/// Used Only inside
/// ```dart
/// NotificationManager.instance.configureQueues(Set<Queue>)
/// ```
/// to configure Queue layouts.
///
/// If no [NotificationQueue] is provided for a [AlignmentDirectional],
/// defaults to a that positions constructor defaults.
@immutable
sealed class NotificationQueue {
  const NotificationQueue({
    required this.alignment,
    required this.maxStackSize,
    required this.dismissalThreshold,
    required this.margin,
    required this.spacing,
    required this.opacity,
    required this.elevation,
    required this.showCloseButton,
    required this.queueIndicatorBuilder,
  });

  final AlignmentDirectional alignment;
  final EdgeInsets? margin;
  final double spacing;
  final int maxStackSize;

  /// Threshold in pixels for drag/long-press dismissal.
  final double dismissalThreshold;

  /// Custom builder for the notification stack indicator.
  final QueueIndicatorBuilder? queueIndicatorBuilder;

  /// Default opacity for notification background.
  final double? opacity;

  /// Default elevation for notification cards.
  final double? elevation;

  /// Whether to show close button.
  final bool showCloseButton;

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is NotificationQueue && other.alignment == alignment;
  }

  @override
  int get hashCode => alignment.hashCode;
}

final class TopStartQueue extends NotificationQueue {
  const TopStartQueue({
    super.margin = const EdgeInsets.all(8.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity,
    super.elevation,
    super.showCloseButton = true,
  }) : super(alignment: AlignmentDirectional.topStart);
}

final class TopCenterQueue extends NotificationQueue {
  const TopCenterQueue({
    super.margin = const EdgeInsets.all(8.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity,
    super.elevation,
    super.showCloseButton = true,
  }) : super(alignment: AlignmentDirectional.topCenter);
}

final class TopEndQueue extends NotificationQueue {
  const TopEndQueue({
    super.margin = const EdgeInsets.all(8.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity,
    super.elevation,
    super.showCloseButton = true,
  }) : super(alignment: AlignmentDirectional.topEnd);
}

final class CenterStartQueue extends NotificationQueue {
  const CenterStartQueue({
    super.margin = const EdgeInsets.all(8.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity,
    super.elevation,
    super.showCloseButton = true,
  }) : super(alignment: AlignmentDirectional.centerStart);
}

final class CenterQueue extends NotificationQueue {
  const CenterQueue({
    super.margin = const EdgeInsets.all(8.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity,
    super.elevation,
    super.showCloseButton = true,
  }) : super(alignment: AlignmentDirectional.center);
}

final class CenterEndQueue extends NotificationQueue {
  const CenterEndQueue({
    super.margin = const EdgeInsets.all(8.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity,
    super.elevation,
    super.showCloseButton = true,
  }) : super(alignment: AlignmentDirectional.centerEnd);
}

final class BottomStartQueue extends NotificationQueue {
  const BottomStartQueue({
    super.margin = const EdgeInsets.all(8.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity,
    super.elevation,
    super.showCloseButton = true,
  }) : super(alignment: AlignmentDirectional.bottomStart);
}

final class BottomCenterQueue extends NotificationQueue {
  const BottomCenterQueue({
    super.margin = const EdgeInsets.all(8.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity,
    super.elevation,
    super.showCloseButton = true,
  }) : super(alignment: AlignmentDirectional.bottomCenter);
}

final class BottomEndQueue extends NotificationQueue {
  const BottomEndQueue({
    super.margin = const EdgeInsets.all(8.0),
    super.spacing = 4.0,
    super.maxStackSize = 3,
    super.queueIndicatorBuilder,
    super.dismissalThreshold = 50.0,
    super.opacity,
    super.elevation,
    super.showCloseButton = true,
  }) : super(alignment: AlignmentDirectional.bottomEnd);
}
