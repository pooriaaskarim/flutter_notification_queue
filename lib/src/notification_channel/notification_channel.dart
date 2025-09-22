import 'package:flutter/material.dart';

import '../../flutter_notification_queue.dart';

part 'standard_channels.dart';

@immutable
class NotificationChannel {
  const NotificationChannel({
    required this.name,
    this.description,
    this.alignment,
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

  /// Whether [NotificationWidget]s from this channel should show.
  final bool enabled;

  /// Whether [NotificationWidget]s from this channel should vibrate.
  final bool vibrate;

  /// [NotificationConfiguration] position on the Screen.
  ///
  /// This binds the Channel [NotificationWidget]s to a [NotificationQueue]
  /// based on the [alignment].
  final AlignmentDirectional? alignment;

  /// Default duration of [NotificationChannel]'s [NotificationConfiguration]s.
  ///
  /// [NotificationConfiguration]s will override with
  /// [NotificationConfiguration.dismissDuration]
  /// If set to null, [NotificationConfiguration]s will be permanent.
  final Duration? defaultDismissDuration;

  /// Default background color of [NotificationChannel]'s
  /// [NotificationConfiguration]s.
  ///
  /// [NotificationConfiguration] will override with
  /// [NotificationConfiguration.backgroundColor] or
  /// if that's null, primary color from
  /// [Theme.of(context).colorScheme.onPrimary].
  final Color? defaultBackgroundColor;

  /// Default foreground color of [NotificationChannel]'s
  /// [NotificationConfiguration]s.
  ///
  /// [NotificationConfiguration] will override
  /// with [NotificationConfiguration.backgroundColor] or
  /// if that's null, onPrimary color from
  /// [Theme.of(context).colorScheme.onPrimary].
  final Color? defaultForegroundColor;

  NotificationChannel copyWith({
    final String? name,
    final String? description,
    final bool? enabled,
    final bool? vibrate,
    final AlignmentDirectional? alignment,
    final Duration? Function()? defaultDismissDuration,
    final Color? Function()? defaultBackgroundColor,
    final Color? Function()? defaultForegroundColor,
  }) =>
      NotificationChannel(
        name: name ?? this.name,
        description: description ?? this.description,
        enabled: enabled ?? this.enabled,
        vibrate: vibrate ?? this.vibrate,
        alignment: alignment ?? this.alignment,
        defaultDismissDuration:
            defaultDismissDuration?.call() ?? this.defaultDismissDuration,
        defaultBackgroundColor:
            defaultBackgroundColor?.call() ?? this.defaultBackgroundColor,
        defaultForegroundColor:
            defaultForegroundColor?.call() ?? this.defaultForegroundColor,
      );

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
