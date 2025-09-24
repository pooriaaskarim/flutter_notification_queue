part of 'notification_queue.dart';

extension NotificationQueueExtensions on NotificationQueue {
  EdgeInsetsGeometry? get margin {
    switch (this) {
      case TopStartQueue():
      case CenterStartQueue():
      case BottomStartQueue():
      case TopEndQueue():
      case CenterEndQueue():
      case BottomEndQueue():
        {
          return style._defaultMargin.subtract(EdgeInsetsGeometry.symmetric(
              horizontal: style._defaultMargin.horizontal));
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
