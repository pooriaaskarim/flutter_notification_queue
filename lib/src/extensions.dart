part of 'in_app_notification_manager.dart';

extension ContextExtentions on BuildContext {
  void showInAppNotification(final InAppNotification notification) =>
      InAppNotificationManager.instance.show(notification, this);
}
