import '../in_app_notifications.dart';

/// Creates an action for [InAppNotification].
///
/// [InAppNotification] **will be dismissed**
/// after [onPressed] callback is executed.
/// ```
/// InAppNotificationAction.button(
///       label: 'Text',
///       onPressed: () {},
///       )
/// ```
/// creates a **button** in the *content of the notification* and
/// ```
/// InAppNotificationAction.onTap(
///       onPressed: () {},
///       )
/// ```
/// executes [onPressed] callback *on notification tap*.
class InAppNotificationAction {
  const InAppNotificationAction._({
    required this.label,
    required this.onPressed,
    required this.type,
  });

  /// Creates a buttoned action
  factory InAppNotificationAction.button({
    required final String label,
    required final void Function() onPressed,
  }) =>
      InAppNotificationAction._(
        label: label,
        onPressed: onPressed,
        type: InAppNotificationActionType.button,
      );

  /// Creates callback on [InAppNotification] tap
  factory InAppNotificationAction.onTap({
    required final void Function() onPressed,
  }) =>
      InAppNotificationAction._(
        label: null,
        onPressed: onPressed,
        type: InAppNotificationActionType.onTap,
      );

  /// Action Label text
  final String? label;

  /// Action onPressed callback
  final void Function() onPressed;

  /// Action type of [InAppNotificationActionType]
  final InAppNotificationActionType type;
}

/// Type of action for [InAppNotification].
///
/// [button] creates a **button** bellow the [InAppNotification.message].
/// [onTap] executes [InAppNotificationAction.onPressed] callback
/// *on notification tap*.
enum InAppNotificationActionType {
  button,
  onTap;
}
