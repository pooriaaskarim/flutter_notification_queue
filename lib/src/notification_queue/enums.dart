part of 'notification_queue.dart';

enum QueuePosition {
  topStart,
  topCenter,
  topEnd,
  centerStart,
  // center,
  centerEnd,
  bottomStart,
  bottomCenter,
  bottomEnd;

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
      case topStart:
        return TopStartQueue(
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
      case topEnd:
        return TopEndQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case centerStart:
        return CenterStartQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      // case center:
      //   return CenterQueue(
      //     style: style,
      //     spacing: spacing,
      //     maxStackSize: maxStackSize,
      //     dismissalThreshold: dismissalThreshold,
      //     queueIndicatorBuilder: queueIndicatorBuilder,
      //   );
      case centerEnd:
        return CenterEndQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case bottomStart:
        return BottomStartQueue(
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
      case bottomEnd:
        return BottomEndQueue(
          style: style,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
    }
  }

  AlignmentDirectional get alignment {
    switch (this) {
      case topCenter:
        return AlignmentDirectional.topCenter;
      case topStart:
        return AlignmentDirectional.topStart;
      case topEnd:
        return AlignmentDirectional.topEnd;
      // case center:
      //   return AlignmentDirectional.center;
      case centerStart:
        return AlignmentDirectional.centerStart;
      case centerEnd:
        return AlignmentDirectional.centerEnd;
      case bottomCenter:
        return AlignmentDirectional.bottomCenter;
      case bottomStart:
        return AlignmentDirectional.bottomStart;
      case bottomEnd:
        return AlignmentDirectional.bottomCenter;
    }
  }

  MainAxisAlignment get mainAxisAlignment {
    switch (this) {
      case topCenter:
      case topStart:
      case topEnd:
        return MainAxisAlignment.start;
      // case center:
      case centerStart:
      case centerEnd:
        return MainAxisAlignment.center;
      case bottomCenter:
      case bottomStart:
      case bottomEnd:
        return MainAxisAlignment.end;
    }
  }

  CrossAxisAlignment get crossAxisAlignment {
    switch (this) {
      case topCenter:
      case bottomCenter:
        // case center:
        return CrossAxisAlignment.center;
      case topStart:
      case bottomStart:
      case centerStart:
        return CrossAxisAlignment.start;
      case topEnd:
      case bottomEnd:
      case centerEnd:
        return CrossAxisAlignment.end;
    }
  }

  VerticalDirection get verticalDirection {
    switch (this) {
      case topCenter:
      case topStart:
      case topEnd:
      // case center:
      case centerStart:
      case centerEnd:
        return VerticalDirection.down;
      case bottomCenter:
      case bottomStart:
      case bottomEnd:
        return VerticalDirection.up;
    }
  }

  Offset get slideTransitionOffset {
    switch (this) {
      case topStart:
      case centerStart:
      case bottomStart:
        return const Offset(-1, 0);
      case topCenter:
        return const Offset(0, -1);
      // case center:
      //   return Offset.zero;
      case bottomCenter:
        return const Offset(0, 1);
      case topEnd:
      case centerEnd:
      case bottomEnd:
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
