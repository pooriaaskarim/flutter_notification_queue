import 'package:flutter/material.dart';

import '../../flutter_notification_queue.dart';

const infoColor = Color(0xFF51B4F9);
const warningColor = Color(0xFFC97725);
const errorColor = Color(0xFFD03332);
const successColor = Color(0xFF2D7512);

@immutable
class NotificationChannel {
  factory NotificationChannel.defaultChannel({
    final String? description = 'Default notification channel.',
    final QueuePosition? position,
    final Duration? defaultDismissDuration,
    final Color? defaultColor,
    final Color? defaultBackgroundColor,
    final Color? defaultForegroundColor,
    final Widget? defaultIcon,
    final bool enabled = true,
    final bool vibrate = false,
  }) =>
      NotificationChannel(
        name: 'default',
        description: description,
        defaultColor: defaultColor,
        defaultDismissDuration: defaultDismissDuration,
        defaultBackgroundColor: defaultBackgroundColor,
        enabled: enabled,
        defaultForegroundColor: defaultForegroundColor,
        defaultIcon: defaultIcon,
        position: position,
        vibrate: vibrate,
      );

  factory NotificationChannel.successChannel({
    final String? description = 'Success notification channel.',
    final QueuePosition? position,
    final Duration? defaultDismissDuration = const Duration(seconds: 5),
    final Color? defaultColor = successColor,
    final Color? defaultBackgroundColor,
    final Color? defaultForegroundColor,
    final Widget? defaultIcon = const Icon(Icons.check_circle),
    final bool enabled = true,
    final bool vibrate = false,
  }) =>
      NotificationChannel(
        name: 'success',
        description: description,
        position: position,
        defaultDismissDuration: defaultDismissDuration,
        defaultColor: defaultColor,
        defaultBackgroundColor: defaultBackgroundColor,
        defaultForegroundColor: defaultForegroundColor,
        defaultIcon: defaultIcon,
        enabled: enabled,
        vibrate: vibrate,
      );

  factory NotificationChannel.infoChannel({
    final String? description = 'Info notification channel.',
    final QueuePosition? position,
    final Duration? defaultDismissDuration = const Duration(seconds: 5),
    final Color? defaultColor = infoColor,
    final Color? defaultBackgroundColor,
    final Color? defaultForegroundColor,
    final Widget? defaultIcon = const Icon(Icons.info),
    final bool enabled = true,
    final bool vibrate = false,
  }) =>
      NotificationChannel(
        name: 'info',
        description: description,
        position: position,
        defaultDismissDuration: defaultDismissDuration,
        defaultColor: defaultColor,
        defaultBackgroundColor: defaultBackgroundColor,
        defaultForegroundColor: defaultForegroundColor,
        defaultIcon: defaultIcon,
        enabled: enabled,
        vibrate: vibrate,
      );

  factory NotificationChannel.errorChannel({
    final String? description = 'Error notification channel.',
    final QueuePosition? position,
    final Duration? defaultDismissDuration = const Duration(seconds: 5),
    final Color? defaultColor = errorColor,
    final Color? defaultBackgroundColor,
    final Color? defaultForegroundColor,
    final Widget? defaultIcon = const Icon(Icons.error),
    final bool enabled = true,
    final bool vibrate = false,
  }) =>
      NotificationChannel(
        name: 'error',
        description: description,
        position: position,
        defaultDismissDuration: defaultDismissDuration,
        defaultColor: defaultColor,
        defaultBackgroundColor: defaultBackgroundColor,
        defaultForegroundColor: defaultForegroundColor,
        defaultIcon: defaultIcon,
        enabled: enabled,
        vibrate: vibrate,
      );

  factory NotificationChannel.warningChannel({
    final String? description = 'Warning notification channel.',
    final QueuePosition? position,
    final Duration? defaultDismissDuration = const Duration(seconds: 5),
    final Color? defaultColor = warningColor,
    final Color? defaultBackgroundColor,
    final Color? defaultForegroundColor,
    final Widget? defaultIcon = const Icon(Icons.warning),
    final bool enabled = true,
    final bool vibrate = false,
  }) =>
      NotificationChannel(
        name: 'warning',
        description: description,
        position: position,
        defaultDismissDuration: defaultDismissDuration,
        defaultColor: defaultColor,
        defaultBackgroundColor: defaultBackgroundColor,
        defaultForegroundColor: defaultForegroundColor,
        defaultIcon: defaultIcon,
        enabled: enabled,
        vibrate: vibrate,
      );
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

  static Set<NotificationChannel> standardChannels({
    final QueuePosition? position,
    final Duration? defaultDismissDuration = const Duration(seconds: 5),
    final bool enabled = true,
    final bool vibrate = false,
  }) =>
      {
        NotificationChannel.successChannel(
          position: position,
          defaultDismissDuration: defaultDismissDuration,
          enabled: enabled,
          vibrate: vibrate,
        ),
        NotificationChannel.infoChannel(
          position: position,
          defaultDismissDuration: defaultDismissDuration,
          enabled: enabled,
          vibrate: vibrate,
        ),
        NotificationChannel.errorChannel(
          position: position,
          defaultDismissDuration: defaultDismissDuration,
          enabled: enabled,
          vibrate: vibrate,
        ),
        NotificationChannel.warningChannel(
          position: position,
          defaultDismissDuration: defaultDismissDuration,
          enabled: enabled,
          vibrate: vibrate,
        ),
      };

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
  /// [NotificationQueue.position] position will override
  /// [NotificationChannel.position]
  /// if available.
  /// If null, binds to the system's default [NotificationQueue].
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
