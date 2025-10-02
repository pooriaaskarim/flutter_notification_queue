part of 'notification_queue.dart';

sealed class QueueStyle {
  const QueueStyle({
    required this.borderRadius,
    required this.opacity,
    required this.elevation,
  });
  final BorderRadiusGeometry borderRadius;
  final double opacity;
  final double elevation;
}

final class FlatQueueStyle extends QueueStyle {
  const FlatQueueStyle({
    super.opacity = 0.7,
    super.borderRadius = BorderRadiusGeometry.zero,
    super.elevation = 3,
  });
}

final class FilledQueueStyle extends QueueStyle {
  const FilledQueueStyle({
    super.opacity = 0.7,
    super.borderRadius = const BorderRadius.all(Radius.circular(8)),
    super.elevation = 3,
  });
}

final class OutlinedQueueStyle extends QueueStyle {
  const OutlinedQueueStyle({
    super.opacity = 0.7,
    super.borderRadius = const BorderRadius.all(Radius.circular(8)),
    super.elevation = 3,
  });
}
