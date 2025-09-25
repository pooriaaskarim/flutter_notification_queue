part of 'notification_queue.dart';

enum QueuePosition {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight;

  NotificationQueue generateQueueFrom(final NotificationQueue anotherQueue) =>
      generateQueue(
        style: anotherQueue.style,
        spacing: anotherQueue.spacing,
        maxStackSize: anotherQueue.maxStackSize,
        dismissalThreshold: anotherQueue.dismissalThreshold,
      );

  NotificationQueue generateQueue({
    required final QueueStyle style,
    required final double spacing,
    required final int maxStackSize,
    required final double dismissalThreshold,
    final PendingIndicatorBuilder? queueIndicatorBuilder,
  }) {
    switch (this) {
      case topLeft:
        return TopLeftQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case topCenter:
        return TopCenterQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case topRight:
        return TopRightQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case centerLeft:
        return CenterLeftQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case centerRight:
        return CenterRightQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case bottomLeft:
        return BottomLeftQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case bottomCenter:
        return BottomCenterQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case bottomRight:
        return BottomRightQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
    }
  }

  AlignmentGeometry get alignment {
    switch (this) {
      case topLeft:
        return Alignment.topLeft;
      case topCenter:
        return Alignment.topCenter;
      case topRight:
        return Alignment.topRight;
      case centerLeft:
        return Alignment.centerLeft;
      case centerRight:
        return Alignment.centerRight;

      case bottomLeft:
        return Alignment.bottomLeft;
      case bottomCenter:
        return Alignment.bottomCenter;
      case bottomRight:
        return Alignment.bottomRight;
    }
  }

  MainAxisAlignment get mainAxisAlignment {
    switch (this) {
      case topCenter:
      case topLeft:
      case topRight:
        return MainAxisAlignment.start;
      case centerLeft:
      case centerRight:
        return MainAxisAlignment.center;
      case bottomCenter:
      case bottomLeft:
      case bottomRight:
        return MainAxisAlignment.end;
    }
  }

  CrossAxisAlignment get crossAxisAlignment {
    switch (this) {
      case topCenter:
      case bottomCenter:
        return CrossAxisAlignment.center;
      case topLeft:
      case bottomLeft:
      case centerLeft:
        return CrossAxisAlignment.start;
      case topRight:
      case bottomRight:
      case centerRight:
        return CrossAxisAlignment.end;
    }
  }

  VerticalDirection get verticalDirection {
    switch (this) {
      case topCenter:
      case topLeft:
      case topRight:
      case centerLeft:
      case centerRight:
        return VerticalDirection.down;
      case bottomCenter:
      case bottomLeft:
      case bottomRight:
        return VerticalDirection.up;
    }
  }

  Offset get slideTransitionOffset {
    switch (this) {
      case topLeft:
      case centerLeft:
      case bottomLeft:
        return const Offset(-1, 0);
      case topCenter:
        return const Offset(0, -1);

      case bottomCenter:
        return const Offset(0, 1);
      case topRight:
      case centerRight:
      case bottomRight:
        return const Offset(1, 0);
    }
  }
}

enum QueueCloseButton {
  always,
  onHover,
  never;
}

sealed class QueueStyle {
  const QueueStyle({
    required this.elevation,
    required this.showCloseButton,
    required this.docked,
  });
  final bool docked;

  final double elevation;
  final QueueCloseButton showCloseButton;
  double get _defaultOpacity => 0.8;
  EdgeInsets get _defaultMargin =>
      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36.0);
  BorderRadius get _defaultBorderRadius =>
      const BorderRadius.all(Radius.circular(4));
}

final class FlatQueueStyle extends QueueStyle {
  const FlatQueueStyle({
    super.docked = false,
    super.showCloseButton = QueueCloseButton.never,
    super.elevation = 3,
  });
}

final class FilledQueueStyle extends QueueStyle {
  const FilledQueueStyle({
    super.docked = false,
    super.showCloseButton = QueueCloseButton.never,
    super.elevation = 3,
  });
}

final class OutlinedQueueStyle extends QueueStyle {
  const OutlinedQueueStyle({
    super.docked = false,
    super.showCloseButton = QueueCloseButton.never,
    super.elevation = 3,
  });
}
