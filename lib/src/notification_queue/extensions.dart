part of 'notification_queue.dart';

extension NotificationQueueExtensions on NotificationQueue {
  EdgeInsetsGeometry? get margin {
    switch (this) {
      case TopLeftQueue():
      case CenterLeftQueue():
      case BottomLeftQueue():
      case TopRightQueue():
      case CenterRightQueue():
      case BottomRightQueue():
        {
          if (style.docked) {
            return EdgeInsetsGeometry.symmetric(
                vertical: style._defaultMargin.top);
          }
          return style._defaultMargin;
        }
      case TopCenterQueue():
      case BottomCenterQueue():
        {
          if (style.docked) {
            return null;
          }
          return style._defaultMargin;
        }
    }
  }

  double get opacity => style._defaultOpacity;

  double get elevation => style.elevation;
}
