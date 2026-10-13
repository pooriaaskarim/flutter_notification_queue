part of 'notification_queue.dart';

sealed class QueueStyle {
  const QueueStyle({
    required this.borderRadius,
    required this.opacity,
    required this.elevation,
    this.padding,
    this.borderWidth,
  });
  final BorderRadiusGeometry borderRadius;
  final double opacity;
  final double elevation;
  final EdgeInsetsGeometry? padding;
  final double? borderWidth;
}

final class FlatQueueStyle extends QueueStyle {
  const FlatQueueStyle({
    super.opacity = 0.7,
    super.borderRadius = BorderRadiusGeometry.zero,
    super.elevation = 3,
    super.padding,
    super.borderWidth = 4.0,
  });
}

final class FilledQueueStyle extends QueueStyle {
  const FilledQueueStyle({
    super.opacity = 0.7,
    super.borderRadius = const BorderRadius.all(Radius.circular(8)),
    super.elevation = 3,
    super.padding,
    super.borderWidth = 1.0,
  });
}

final class OutlinedQueueStyle extends QueueStyle {
  const OutlinedQueueStyle({
    super.opacity = 0.7,
    super.borderRadius = const BorderRadius.all(Radius.circular(8)),
    super.elevation = 3,
    super.padding,
    super.borderWidth = 1.0,
  });
}
