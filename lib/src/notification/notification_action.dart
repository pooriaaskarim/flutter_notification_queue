part of 'notification.dart';

/// Creates an action for [StandardNotificationWidget].
///
/// [StandardNotificationWidget] **will be dismissed**
/// after [onPressed] callback is executed.
/// ```
/// QuetificationAction.button(
///       label: 'Text',
///       onPressed: () {},
///       )
/// ```
/// creates a **button** in the *content of the notification* and
/// ```
/// QuetificationAction.onTap(
///       onPressed: () {},
///       )
/// ```
/// executes [onPressed] callback *on notification tap*.
class NotificationAction {
  const NotificationAction._({
    required this.label,
    required this.onPressed,
    required this.type,
  });

  /// Creates a buttoned action
  factory NotificationAction.button({
    required final String label,
    required final void Function() onPressed,
  }) =>
      NotificationAction._(
        label: label,
        onPressed: onPressed,
        type: NotificationActionType.button,
      );

  /// Creates callback on [StandardNotificationWidget] tap
  factory NotificationAction.onTap({
    required final void Function() onPressed,
  }) =>
      NotificationAction._(
        label: null,
        onPressed: onPressed,
        type: NotificationActionType.onTap,
      );

  /// Action Label text
  final String? label;

  /// Action onPressed callback
  final void Function() onPressed;

  /// Action type of [NotificationActionType]
  final NotificationActionType type;
}

/// Type of action for [StandardNotificationWidget].
///
/// [button] creates a **button** bellow the [StandardNotificationWidget.message].
/// [onTap] executes [NotificationAction.onPressed] callback
/// *on notification tap*.
enum NotificationActionType {
  button,
  onTap;
}
