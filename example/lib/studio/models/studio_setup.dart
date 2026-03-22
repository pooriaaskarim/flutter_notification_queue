import 'package:equatable/equatable.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import 'channel_setup.dart';
import 'queue_setup.dart';

/// The complete Studio configuration — all queues + all channels.
///
/// This is the **single source of truth** passed to
/// [FlutterNotificationQueue.configure].
class StudioSetup extends Equatable {
  const StudioSetup({
    this.queues = const {QueuePosition.topCenter: QueueSetup()},
    this.channels = const {},
  });

  /// Creates a [StudioSetup] with one default queue and standard channels.
  factory StudioSetup.withDefaults() => StudioSetup(
        channels: ChannelSetup.standardChannels(),
      );

  /// Queue configurations keyed by position.
  final Map<QueuePosition, QueueSetup> queues;

  /// Channel configurations keyed by name.
  final Map<String, ChannelSetup> channels;

  StudioSetup copyWith({
    final Map<QueuePosition, QueueSetup>? queues,
    final Map<String, ChannelSetup>? channels,
  }) =>
      StudioSetup(
        queues: queues ?? this.queues,
        channels: channels ?? this.channels,
      );

  // ── Library Mappers ──

  /// Converts all queue setups to library [NotificationQueue] instances.
  Set<NotificationQueue> toLibraryQueues() => queues.entries
      .map(
        (final e) => e.value.toNotificationQueue(e.key),
      )
      .toSet();

  /// Converts all channel setups to library [NotificationChannel] instances.
  Set<NotificationChannel> toLibraryChannels() => channels.values
      .map(
        (final c) => c.toNotificationChannel(),
      )
      .toSet();

  @override
  List<Object?> get props => [queues, channels];
}
