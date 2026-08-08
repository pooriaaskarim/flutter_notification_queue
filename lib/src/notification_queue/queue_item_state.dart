part of 'notification_queue.dart';

enum _ItemStatus { entering, exiting }

class _NotificationItemState {
  _NotificationItemState({
    required this.entry,
    required this.controller,
  });

  NotificationEntry entry;
  NotificationWidget get widget => entry.blueprint;
  final AnimationController controller;
  final GlobalKey globalKey = GlobalKey();
  _ItemStatus status = _ItemStatus.entering;

  /// Regenerated on each instant-swap so the representative's
  /// TweenAnimationBuilder re-triggers its entrance micro-animation.
  Key entranceKey = UniqueKey();
}
