import 'package:flutter/widgets.dart';

/// A utility class for carrying local and global offsets of a drag event.
class OffsetPair {
  const OffsetPair({required this.local, required this.global});
  final Offset local;
  final Offset global;
}
