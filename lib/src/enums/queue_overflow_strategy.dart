part of 'enums.dart';

/// Strategy for handling queue overflow when the pending queue
/// exceeds its limit.
enum QueueOverflowStrategy {
  /// Discards the oldest pending notification in the queue to make room for
  /// the new one.
  discardOldest,

  /// Discards the newly incoming notification directly, leaving the pending
  /// queue unchanged.
  discardNewest,
}
