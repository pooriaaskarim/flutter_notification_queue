part of 'notification_queue.dart';

enum QueuePosition {
  topStart,
  topCenter,
  topEnd,
  centerStart,
  center,
  centerEnd,
  bottomStart,
  bottomCenter,
  bottomEnd;

  NotificationQueue generateQueueFrom(final NotificationQueue anotherQueue) =>
      generateQueue(
        spacing: anotherQueue.spacing,
        maxStackSize: anotherQueue.maxStackSize,
        dismissalThreshold: anotherQueue.dismissalThreshold,
        showCloseButton: anotherQueue.showCloseButton,
        queueIndicatorBuilder: anotherQueue.queueIndicatorBuilder,
        opacity: anotherQueue.opacity,
        elevation: anotherQueue.elevation,
        margin: anotherQueue.margin,
      );

  NotificationQueue generateQueue({
    required final double spacing,
    required final int maxStackSize,
    required final double dismissalThreshold,
    required final bool showCloseButton,
    final PendingIndicatorBuilder? queueIndicatorBuilder,
    final double opacity = 0.8,
    final double elevation = 3,
    final EdgeInsets? margin,
  }) {
    switch (this) {
      case topStart:
        return TopStartQueue(
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
          opacity: opacity,
          elevation: elevation,
          showCloseButton: showCloseButton,
        );
      case topCenter:
        return TopCenterQueue(
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
          opacity: opacity,
          elevation: elevation,
          showCloseButton: showCloseButton,
        );
      case topEnd:
        return TopEndQueue(
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
          opacity: opacity,
          elevation: elevation,
          showCloseButton: showCloseButton,
        );
      case centerStart:
        return CenterStartQueue(
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
          opacity: opacity,
          elevation: elevation,
          showCloseButton: showCloseButton,
        );
      case center:
        return CenterQueue(
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
          opacity: opacity,
          elevation: elevation,
          showCloseButton: showCloseButton,
        );
      case centerEnd:
        return CenterEndQueue(
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
          opacity: opacity,
          elevation: elevation,
          showCloseButton: showCloseButton,
        );
      case bottomStart:
        return BottomStartQueue(
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
          opacity: opacity,
          elevation: elevation,
          showCloseButton: showCloseButton,
        );
      case bottomCenter:
        return BottomCenterQueue(
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
          opacity: opacity,
          elevation: elevation,
          showCloseButton: showCloseButton,
        );
      case bottomEnd:
        return BottomEndQueue(
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dismissalThreshold: dismissalThreshold,
          queueIndicatorBuilder: queueIndicatorBuilder,
          opacity: opacity,
          elevation: elevation,
          showCloseButton: showCloseButton,
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
      case center:
        return AlignmentDirectional.center;
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
      case center:
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
      case center:
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
      case center:
      case centerStart:
      case centerEnd:
        return VerticalDirection.down;
      case bottomCenter:
      case bottomStart:
      case bottomEnd:
        return VerticalDirection.up;
    }
  }
}
