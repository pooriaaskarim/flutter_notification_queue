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
    this.defaultColor,
    this.defaultForegroundColor,
    this.defaultBackgroundColor,
    this.defaultIcon,
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

  /// Default notification color of the channel.
  ///
  /// Colors icon, borders and filled [QueueStyle]s' background color.
  /// [NotificationWidget]s can override with [NotificationWidget.color].
  /// Filled [QueueStyle]s will color notification body and foreground
  /// according to this.
  final Color? defaultColor;

  /// Default foreground color of channel notifications.
  ///
  /// Colors text, close, expand and action buttons and progressIndicator.
  /// [NotificationWidget]s can override with
  /// [NotificationWidget.foregroundColor].
  /// Filled [QueueStyle]s will ignore foreground color and color notification
  /// foreground using a high-contrast color to [defaultColor].
  final Color? defaultForegroundColor;

  /// Default background color of [NotificationChannel]'s
  /// [NotificationWidget]s.
  ///
  /// Colors notification body.
  /// [NotificationWidget]s can override with
  /// [NotificationWidget.backgroundColor].
  /// Filled [QueueStyle]s will ignore background color and color notification
  /// body with [defaultColor].
  final Color? defaultBackgroundColor;

  /// Default channel Icon
  final Widget? defaultIcon;

  @override
  String toString() => 'NotificationChannel{name: $name'
      '${description != null ? ', description: $description,\n' : ''}}';
}
