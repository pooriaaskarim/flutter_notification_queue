import 'package:flutter/material.dart';

import '../../flutter_notification_queue.dart';

part 'standard_channels.dart';

@immutable
class NotificationChannel {
  const NotificationChannel({
    required this.name,
    this.description,
    this.position,
    this.enabled = true,
    this.vibrate = true,
    this.defaultBackgroundColor,
    this.defaultForegroundColor,
    this.defaultDismissDuration,
  });

  /// Channel Name
  final String name;

  /// A brief description of Channel Intention
  final String? description;

  /// Whether [NotificationWidget]s from this channel should  be shown.
  //Todo: UnderDevelop
  final bool enabled;

  /// Whether [NotificationWidget]s from this channel should vibrate.
  //Todo: UnderDevelop
  final bool vibrate;

  /// [NotificationChannel]'s default [NotificationQueue].
  ///
  /// This binds the Channel [NotificationWidget]s to a [NotificationQueue]
  /// based on the [position].
  /// [NotificationWidget.position] will override [NotificationChannel.position]
  /// if available.
  /// If null, binds to [NotificationManager]'s default [NotificationQueue].
  final QueuePosition? position;

  /// Default duration of channel [NotificationWidget]s.
  ///
  /// [NotificationWidget.dismissDuration]s will override with
  /// [NotificationChannel.defaultDismissDuration]
  /// If set to null, channel [NotificationWidget]s will be permanent.
  final Duration? defaultDismissDuration;

  /// Default background color of [NotificationChannel]'s
  /// [NotificationWidget]s.
  final Color? defaultBackgroundColor;

  /// Default foreground color of [NotificationChannel]'s
  /// [NotificationWidget]s.

  final Color? defaultForegroundColor;

  NotificationChannel copyWith({
    final String? name,
    final String? description,
    final bool? enabled,
    final bool? vibrate,
    final QueuePosition? Function()? position,
    final Duration? Function()? defaultDismissDuration,
    final Color? Function()? defaultBackgroundColor,
    final Color? Function()? defaultForegroundColor,
  }) =>
      NotificationChannel(
        name: name ?? this.name,
        description: description ?? this.description,
        enabled: enabled ?? this.enabled,
        vibrate: vibrate ?? this.vibrate,
        position: position?.call() ?? this.position,
        defaultDismissDuration:
            defaultDismissDuration?.call() ?? this.defaultDismissDuration,
        defaultBackgroundColor:
            defaultBackgroundColor?.call() ?? this.defaultBackgroundColor,
        defaultForegroundColor:
            defaultForegroundColor?.call() ?? this.defaultForegroundColor,
      );

  @override
  String toString() => '"$name" NotificationChannel';
  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is NotificationChannel && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
