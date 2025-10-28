// part of 'notification_queue.dart';
//
// enum QueuePosition {
//   topLeft,
//   topCenter,
//   topRight,
//   centerLeft,
//   centerRight,
//   bottomLeft,
//   bottomCenter,
//   bottomRight;
//
//   NotificationQueue generateQueueFrom(final NotificationQueue anotherQueue) =>
//       generateQueue(
//         style: anotherQueue.style,
//         margin: anotherQueue.margin,
//         spacing: anotherQueue.spacing,
//         maxStackSize: anotherQueue.maxStackSize,
//         longPressDragBehaviour: anotherQueue.longPressDragBehaviour,
//         dragBehaviour: anotherQueue.dragBehaviour,
//         closeButtonBehaviour: anotherQueue.closeButtonBehaviour,
//         queueIndicatorBuilder: anotherQueue.queueIndicatorBuilder,
//       );
//
//   NotificationQueue generateQueue({
//     required final QueueStyle style,
//     required final double spacing,
//     required final EdgeInsetsGeometry margin,
//     required final int maxStackSize,
//     required final DragBehaviour dragBehaviour,
//     required final LongPressDragBehaviour longPressDragBehaviour,
//     required final QueueCloseButtonBehaviour closeButtonBehaviour,
//     required final QueueIndicatorBuilder? queueIndicatorBuilder,
//   }) {
//     switch (this) {
//       case topLeft:
//         return TopLeftQueue(
//           style: style,
//           margin: margin,
//           spacing: spacing,
//           maxStackSize: maxStackSize,
//           dragBehaviour: dragBehaviour,
//           longPressDragBehaviour: longPressDragBehaviour,
//           closeButtonBehaviour: closeButtonBehaviour,
//           queueIndicatorBuilder: queueIndicatorBuilder,
//         );
//       case topCenter:
//         return TopCenterQueue(
//           style: style,
//           margin: margin,
//           spacing: spacing,
//           maxStackSize: maxStackSize,
//           dragBehaviour: dragBehaviour,
//           longPressDragBehaviour: longPressDragBehaviour,
//           closeButtonBehaviour: closeButtonBehaviour,
//           queueIndicatorBuilder: queueIndicatorBuilder,
//         );
//       case topRight:
//         return TopRightQueue(
//           style: style,
//           margin: margin,
//           spacing: spacing,
//           maxStackSize: maxStackSize,
//           dragBehaviour: dragBehaviour,
//           longPressDragBehaviour: longPressDragBehaviour,
//           closeButtonBehaviour: closeButtonBehaviour,
//           queueIndicatorBuilder: queueIndicatorBuilder,
//         );
//       case centerLeft:
//         return CenterLeftQueue(
//           style: style,
//           margin: margin,
//           spacing: spacing,
//           maxStackSize: maxStackSize,
//           dragBehaviour: dragBehaviour,
//           longPressDragBehaviour: longPressDragBehaviour,
//           closeButtonBehaviour: closeButtonBehaviour,
//           queueIndicatorBuilder: queueIndicatorBuilder,
//         );
//       case centerRight:
//         return CenterRightQueue(
//           style: style,
//           margin: margin,
//           spacing: spacing,
//           maxStackSize: maxStackSize,
//           dragBehaviour: dragBehaviour,
//           longPressDragBehaviour: longPressDragBehaviour,
//           closeButtonBehaviour: closeButtonBehaviour,
//           queueIndicatorBuilder: queueIndicatorBuilder,
//         );
//       case bottomLeft:
//         return BottomLeftQueue(
//           style: style,
//           margin: margin,
//           spacing: spacing,
//           maxStackSize: maxStackSize,
//           dragBehaviour: dragBehaviour,
//           longPressDragBehaviour: longPressDragBehaviour,
//           closeButtonBehaviour: closeButtonBehaviour,
//           queueIndicatorBuilder: queueIndicatorBuilder,
//         );
//       case bottomCenter:
//         return BottomCenterQueue(
//           style: style,
//           margin: margin,
//           spacing: spacing,
//           maxStackSize: maxStackSize,
//           dragBehaviour: dragBehaviour,
//           longPressDragBehaviour: longPressDragBehaviour,
//           closeButtonBehaviour: closeButtonBehaviour,
//           queueIndicatorBuilder: queueIndicatorBuilder,
//         );
//       case bottomRight:
//         return BottomRightQueue(
//           style: style,
//           margin: margin,
//           spacing: spacing,
//           maxStackSize: maxStackSize,
//           dragBehaviour: dragBehaviour,
//           longPressDragBehaviour: longPressDragBehaviour,
//           closeButtonBehaviour: closeButtonBehaviour,
//           queueIndicatorBuilder: queueIndicatorBuilder,
//         );
//     }
//   }
//
//   AlignmentGeometry get alignment {
//     switch (this) {
//       case topLeft:
//         return Alignment.topLeft;
//       case topCenter:
//         return Alignment.topCenter;
//       case topRight:
//         return Alignment.topRight;
//       case centerLeft:
//         return Alignment.centerLeft;
//       case centerRight:
//         return Alignment.centerRight;
//
//       case bottomLeft:
//         return Alignment.bottomLeft;
//       case bottomCenter:
//         return Alignment.bottomCenter;
//       case bottomRight:
//         return Alignment.bottomRight;
//     }
//   }
// }
//
// enum QueueCloseButtonBehaviour {
//   always,
//   onHover,
//   never;
// }
//
// // /// How [NotificationWidget]s inside the [NotificationQueue] will relocate on
// // /// the screen.
// // ///
// // /// As this moment, [NotificationWidget]s will follow [NotificationQueue]
// // /// styles; if they are already define, the pre-configured style will be
// // /// replaced. And if not, current [NotificationQueue] style will be used.
// // sealed class QueueRelocationBehaviour {
// //   const QueueRelocationBehaviour(
// //     this.positions, {
// //     required this.thresholdInPixels,
// //     required this.adaptive,
// //   });
// //
// //   /// Positions to relocate [NotificationWidget]s to.
// //   ///
// //   /// Not supposed to be empty.
// //   /// Not supposed to contain the same position as the [NotificationQueue].
// //   /// Recommended to limit positions to the same height
// //   /// as the [NotificationQueue].
// //   final Set<QueuePosition> positions;
// //
// //   /// Pixels left from screen edge to trigger relocation.
// //   final int thresholdInPixels;
// //
// //   /// Whether to prevent relocation on smaller width screens.
// //   ///
// //   /// This will prevent relocation of [NotificationWidget]s will overlap
// //   /// inside *Same Height* [NotificationQueue]s.
// //   /// Recommended to be enabled.
// //   final bool adaptive;
// // }
// //
// // final class LongPressRelocationBehaviour extends QueueRelocationBehaviour {
// //   const LongPressRelocationBehaviour(
// //     super.positions, {
// //     super.thresholdInPixels = 50,
// //     super.adaptive = true,
// //   });
// // }
// //
// // final class DragRelocationBehaviour extends QueueRelocationBehaviour {
// //   const DragRelocationBehaviour(
// //     super.positions, {
// //     super.thresholdInPixels = 50,
// //     super.adaptive = true,
// //   });
// // }
// //
// // final class DisabledRelocationBehaviour extends QueueRelocationBehaviour {
// //   const DisabledRelocationBehaviour()
// //       : super(
// //           const {},
// //           thresholdInPixels: 50,
// //           adaptive: true,
// //         );
// // }
// //
// // /// How [NotificationWidget]s inside the [NotificationQueue] will be dismissed.
// // sealed class QueueDismissBehaviour {
// //   const QueueDismissBehaviour({required this.thresholdInPixels});
// //
// //   /// Pixels left from screen edge to trigger relocation.
// //   final int thresholdInPixels;
// // }
// //
// // final class DragDismissBehaviour extends QueueDismissBehaviour {
// //   const DragDismissBehaviour({
// //     super.thresholdInPixels = 50,
// //   });
// // }
// //
// // // final class TapDismissBehaviour extends QueueDismissBehaviour {}
// //
// // final class LongPressDismissBehaviour extends QueueDismissBehaviour {
// //   const LongPressDismissBehaviour({
// //     super.thresholdInPixels = 50,
// //   });
// // }
// //
// // final class DisabledDismissBehaviour extends QueueDismissBehaviour {
// //   const DisabledDismissBehaviour()
// //       : super(
// //           thresholdInPixels: 50,
// //         );
// // }
//
// sealed class NotificationBehaviour {
//   const NotificationBehaviour({required this.thresholdInPixels})
//       : assert(
//           thresholdInPixels >= 50,
//           'thresholdInPixels must be greater than 50',
//         );
//   final int thresholdInPixels;
// }
//
// abstract final class RelocateNotificationBehaviour
//     extends NotificationBehaviour {
//   RelocateNotificationBehaviour({
//     required this.positions,
//     super.thresholdInPixels = 50,
//   }) : assert(positions.isNotEmpty, 'toPositions cannot be empty');
//   final Set<QueuePosition> positions;
// }
//
// abstract final class DismissNotificationBehaviour
//     extends NotificationBehaviour {
//   const DismissNotificationBehaviour({
//     super.thresholdInPixels = 50,
//   });
// }
//
// abstract final class DisabledNotificationBehaviour
//     extends NotificationBehaviour {
//   const DisabledNotificationBehaviour()
//       : super(
//           thresholdInPixels: 50,
//         );
// }
//
// sealed class LongPressDragBehaviour {
//   const LongPressDragBehaviour();
// }
//
// final class RelocateLongPressDragBehaviour extends RelocateNotificationBehaviour
//     implements LongPressDragBehaviour {
//   RelocateLongPressDragBehaviour({
//     required super.positions,
//     super.thresholdInPixels = 50,
//   });
// }
//
// final class DismissLongPressDragBehaviour extends DismissNotificationBehaviour
//     implements LongPressDragBehaviour {
//   const DismissLongPressDragBehaviour({
//     super.thresholdInPixels = 50,
//   });
// }
//
// final class DisabledLongPressDragBehaviour extends DisabledNotificationBehaviour
//     implements LongPressDragBehaviour {
//   const DisabledLongPressDragBehaviour();
// }
//
// sealed class DragBehaviour {
//   const DragBehaviour();
// }
//
// final class RelocateDragBehaviour extends RelocateNotificationBehaviour
//     implements DragBehaviour {
//   RelocateDragBehaviour({
//     required super.positions,
//     super.thresholdInPixels = 50,
//   });
// }
//
// final class DismissDragBehaviour extends DismissNotificationBehaviour
//     implements DragBehaviour {
//   const DismissDragBehaviour({
//     super.thresholdInPixels = 50,
//   });
// }
//
// final class DisabledDragBehaviour extends DisabledNotificationBehaviour
//     implements DragBehaviour {
//   const DisabledDragBehaviour();
// }
