part of 'enums.dart';

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
        margin: anotherQueue.margin,
        spacing: anotherQueue.spacing,
        maxStackSize: anotherQueue.maxStackSize,
        longPressDragBehaviour: anotherQueue.longPressDragBehaviour,
        dragBehaviour: anotherQueue.dragBehaviour,
        closeButtonBehaviour: anotherQueue.closeButtonBehaviour,
        queueIndicatorBuilder: anotherQueue.queueIndicatorBuilder,
      );

  NotificationQueue generateQueue({
    required final QueueStyle style,
    required final double spacing,
    required final EdgeInsetsGeometry margin,
    required final int maxStackSize,
    required final DragBehaviour dragBehaviour,
    required final LongPressDragBehaviour longPressDragBehaviour,
    required final QueueCloseButtonBehaviour closeButtonBehaviour,
    required final QueueIndicatorBuilder? queueIndicatorBuilder,
  }) {
    switch (this) {
      case topLeft:
        return TopLeftQueue(
          style: style,
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dragBehaviour: dragBehaviour,
          longPressDragBehaviour: longPressDragBehaviour,
          closeButtonBehaviour: closeButtonBehaviour,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case topCenter:
        return TopCenterQueue(
          style: style,
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dragBehaviour: dragBehaviour,
          longPressDragBehaviour: longPressDragBehaviour,
          closeButtonBehaviour: closeButtonBehaviour,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case topRight:
        return TopRightQueue(
          style: style,
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dragBehaviour: dragBehaviour,
          longPressDragBehaviour: longPressDragBehaviour,
          closeButtonBehaviour: closeButtonBehaviour,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case centerLeft:
        return CenterLeftQueue(
          style: style,
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dragBehaviour: dragBehaviour,
          longPressDragBehaviour: longPressDragBehaviour,
          closeButtonBehaviour: closeButtonBehaviour,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case centerRight:
        return CenterRightQueue(
          style: style,
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dragBehaviour: dragBehaviour,
          longPressDragBehaviour: longPressDragBehaviour,
          closeButtonBehaviour: closeButtonBehaviour,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case bottomLeft:
        return BottomLeftQueue(
          style: style,
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dragBehaviour: dragBehaviour,
          longPressDragBehaviour: longPressDragBehaviour,
          closeButtonBehaviour: closeButtonBehaviour,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case bottomCenter:
        return BottomCenterQueue(
          style: style,
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dragBehaviour: dragBehaviour,
          longPressDragBehaviour: longPressDragBehaviour,
          closeButtonBehaviour: closeButtonBehaviour,
          queueIndicatorBuilder: queueIndicatorBuilder,
        );
      case bottomRight:
        return BottomRightQueue(
          style: style,
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dragBehaviour: dragBehaviour,
          longPressDragBehaviour: longPressDragBehaviour,
          closeButtonBehaviour: closeButtonBehaviour,
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
}
