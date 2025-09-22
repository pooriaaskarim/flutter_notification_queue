part of 'queue_manager.dart';

extension AlignmentDirectionalExtension on NotificationQueue {
  MainAxisAlignment get mainAxisAlignment {
    switch (this) {
      case TopCenterQueue():
      case TopStartQueue():
      case TopEndQueue():
        return MainAxisAlignment.start;
      case CenterQueue():
      case CenterStartQueue():
      case CenterEndQueue():
        return MainAxisAlignment.center;
      case BottomCenterQueue():
      case BottomStartQueue():
      case BottomEndQueue():
        return MainAxisAlignment.end;
    }
  }

  CrossAxisAlignment get crossAxisAlignment {
    switch (this) {
      case TopCenterQueue():
      case BottomCenterQueue():
      case CenterQueue():
        return CrossAxisAlignment.center;
      case TopStartQueue():
      case BottomStartQueue():
      case CenterStartQueue():
        return CrossAxisAlignment.start;
      case TopEndQueue():
      case BottomEndQueue():
      case CenterEndQueue():
        return CrossAxisAlignment.end;
    }
  }

  VerticalDirection get verticalDirection {
    switch (this) {
      case TopCenterQueue():
      case TopStartQueue():
      case TopEndQueue():
      case CenterQueue():
      case CenterStartQueue():
      case CenterEndQueue():
        return VerticalDirection.down;
      case BottomCenterQueue():
      case BottomStartQueue():
      case BottomEndQueue():
        return VerticalDirection.up;
    }
  }
}
