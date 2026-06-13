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
        longPressDragBehavior: anotherQueue.longPressDragBehavior,
        dragBehavior: anotherQueue.dragBehavior,
        tapBehavior: anotherQueue.tapBehavior,
        closeButtonBehavior: anotherQueue.closeButtonBehavior,
        queueIndicatorBuilder: anotherQueue.queueIndicatorBuilder,
        transition: anotherQueue.transition,
        maxPendingSize: anotherQueue.maxPendingSize,
        overflowStrategy: anotherQueue.overflowStrategy,
        maxWidth: anotherQueue.maxWidth,
        groupingBehavior: anotherQueue.groupingBehavior,
      );

  NotificationQueue generateQueue({
    required final QueueStyle style,
    required final double spacing,
    required final EdgeInsetsGeometry margin,
    required final int maxStackSize,
    required final DragBehavior dragBehavior,
    required final LongPressDragBehavior longPressDragBehavior,
    required final TapBehavior tapBehavior,
    required final QueueCloseButtonBehavior closeButtonBehavior,
    required final QueueIndicatorBuilder? queueIndicatorBuilder,
    required final NotificationTransition? transition,
    final int? maxPendingSize,
    final QueueOverflowStrategy overflowStrategy =
        QueueOverflowStrategy.discardOldest,
    final double? maxWidth,
    final QueueGroupingBehavior groupingBehavior =
        const QueueGroupingBehavior(),
  }) {
    switch (this) {
      case topLeft:
        return TopLeftQueue(
          style: style,
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dragBehavior: dragBehavior,
          longPressDragBehavior: longPressDragBehavior,
          tapBehavior: tapBehavior,
          closeButtonBehavior: closeButtonBehavior,
          queueIndicatorBuilder: queueIndicatorBuilder,
          transition: transition ?? const SlideTransitionStrategy(),
          maxPendingSize: maxPendingSize,
          overflowStrategy: overflowStrategy,
          maxWidth: maxWidth,
          groupingBehavior: groupingBehavior,
        );
      case topCenter:
        return TopCenterQueue(
          style: style,
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dragBehavior: dragBehavior,
          longPressDragBehavior: longPressDragBehavior,
          tapBehavior: tapBehavior,
          closeButtonBehavior: closeButtonBehavior,
          queueIndicatorBuilder: queueIndicatorBuilder,
          transition: transition ?? const SlideTransitionStrategy(),
          maxPendingSize: maxPendingSize,
          overflowStrategy: overflowStrategy,
          maxWidth: maxWidth,
          groupingBehavior: groupingBehavior,
        );
      case topRight:
        return TopRightQueue(
          style: style,
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dragBehavior: dragBehavior,
          longPressDragBehavior: longPressDragBehavior,
          tapBehavior: tapBehavior,
          closeButtonBehavior: closeButtonBehavior,
          queueIndicatorBuilder: queueIndicatorBuilder,
          transition: transition ?? const SlideTransitionStrategy(),
          maxPendingSize: maxPendingSize,
          overflowStrategy: overflowStrategy,
          maxWidth: maxWidth,
          groupingBehavior: groupingBehavior,
        );
      case centerLeft:
        return CenterLeftQueue(
          style: style,
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dragBehavior: dragBehavior,
          longPressDragBehavior: longPressDragBehavior,
          tapBehavior: tapBehavior,
          closeButtonBehavior: closeButtonBehavior,
          queueIndicatorBuilder: queueIndicatorBuilder,
          transition: transition ?? const SlideTransitionStrategy(),
          maxPendingSize: maxPendingSize,
          overflowStrategy: overflowStrategy,
          maxWidth: maxWidth,
          groupingBehavior: groupingBehavior,
        );
      case centerRight:
        return CenterRightQueue(
          style: style,
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dragBehavior: dragBehavior,
          longPressDragBehavior: longPressDragBehavior,
          tapBehavior: tapBehavior,
          closeButtonBehavior: closeButtonBehavior,
          queueIndicatorBuilder: queueIndicatorBuilder,
          transition: transition ?? const SlideTransitionStrategy(),
          maxPendingSize: maxPendingSize,
          overflowStrategy: overflowStrategy,
          maxWidth: maxWidth,
          groupingBehavior: groupingBehavior,
        );
      case bottomLeft:
        return BottomLeftQueue(
          style: style,
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dragBehavior: dragBehavior,
          longPressDragBehavior: longPressDragBehavior,
          tapBehavior: tapBehavior,
          closeButtonBehavior: closeButtonBehavior,
          queueIndicatorBuilder: queueIndicatorBuilder,
          transition: transition ?? const SlideTransitionStrategy(),
          maxPendingSize: maxPendingSize,
          overflowStrategy: overflowStrategy,
          maxWidth: maxWidth,
          groupingBehavior: groupingBehavior,
        );
      case bottomCenter:
        return BottomCenterQueue(
          style: style,
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dragBehavior: dragBehavior,
          longPressDragBehavior: longPressDragBehavior,
          tapBehavior: tapBehavior,
          closeButtonBehavior: closeButtonBehavior,
          queueIndicatorBuilder: queueIndicatorBuilder,
          transition: transition ?? const SlideTransitionStrategy(),
          maxPendingSize: maxPendingSize,
          overflowStrategy: overflowStrategy,
          maxWidth: maxWidth,
          groupingBehavior: groupingBehavior,
        );
      case bottomRight:
        return BottomRightQueue(
          style: style,
          margin: margin,
          spacing: spacing,
          maxStackSize: maxStackSize,
          dragBehavior: dragBehavior,
          longPressDragBehavior: longPressDragBehavior,
          tapBehavior: tapBehavior,
          closeButtonBehavior: closeButtonBehavior,
          queueIndicatorBuilder: queueIndicatorBuilder,
          transition: transition ?? const SlideTransitionStrategy(),
          maxPendingSize: maxPendingSize,
          overflowStrategy: overflowStrategy,
          maxWidth: maxWidth,
          groupingBehavior: groupingBehavior,
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

  Offset get defaultSlideOffset {
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

  String get displayName {
    switch (this) {
      case QueuePosition.topLeft:
        return 'Top Left';
      case QueuePosition.topCenter:
        return 'Top Center';
      case QueuePosition.topRight:
        return 'Top Right';
      case QueuePosition.centerLeft:
        return 'Center Left';
      case QueuePosition.centerRight:
        return 'Center Right';
      case QueuePosition.bottomLeft:
        return 'Bottom Left';
      case QueuePosition.bottomCenter:
        return 'Bottom Center';
      case QueuePosition.bottomRight:
        return 'Bottom Right';
    }
  }
}
