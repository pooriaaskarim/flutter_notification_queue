part of 'in_app_notification_manager.dart';

extension ContextExtentions on BuildContext {
  void showInAppNotification(final InAppNotification notification) =>
      InAppNotificationManager.instance.show(notification, this);

  void showSuccess(
    final String message, {
    final Key? key,
    final String? title,
    final Duration? dismissDuration,
    final InAppNotificationAction? action,
    final bool permanent = false,
    final bool? showCloseIcon,
  }) =>
      InAppNotificationManager.instance.show(
        InAppNotification.success(
          message: message,
          title: title,
          dismissDuration: dismissDuration,
          action: action,
          permanent: permanent,
          key: key,
          showCloseIcon: showCloseIcon,
        ),
        this,
      );

  void showError(
    final String message, {
    final Key? key,
    final String? title,
    final Duration? dismissDuration,
    final InAppNotificationAction? action,
    final bool permanent = false,
    final bool? showCloseIcon,
  }) =>
      InAppNotificationManager.instance.show(
        InAppNotification.error(
          message: message,
          title: title,
          dismissDuration: dismissDuration,
          action: action,
          permanent: permanent,
          key: key,
          showCloseIcon: showCloseIcon,
        ),
        this,
      );

  void showWarning(
    final String message, {
    final Key? key,
    final String? title,
    final Duration? dismissDuration,
    final InAppNotificationAction? action,
    final bool permanent = false,
    final bool? showCloseIcon,
  }) =>
      InAppNotificationManager.instance.show(
        InAppNotification.warning(
          message: message,
          title: title,
          dismissDuration: dismissDuration,
          action: action,
          permanent: permanent,
          key: key,
          showCloseIcon: showCloseIcon,
        ),
        this,
      );

  void showInfo(
    final String message, {
    final Key? key,
    final String? title,
    final Duration? dismissDuration,
    final InAppNotificationAction? action,
    final bool permanent = false,
    final bool? showCloseIcon,
  }) =>
      InAppNotificationManager.instance.show(
        InAppNotification.info(
          message: message,
          title: title,
          dismissDuration: dismissDuration,
          action: action,
          permanent: permanent,
          key: key,
          showCloseIcon: showCloseIcon,
        ),
        this,
      );
}
