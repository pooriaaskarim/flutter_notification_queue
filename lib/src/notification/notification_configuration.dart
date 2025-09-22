part of 'notification.dart';

/// Configuration for [NotificationWidget] and [NotificationManager].
///
/// Customize colors, timings, and behaviors globally or per-instance.
class NotificationConfiguration {
  const NotificationConfiguration({
    required this.message,
    this.title,
    this.action,
    this.icon,
    this.foregroundColor = Colors.white,
    this.backgroundColor,
    this.dismissDuration = const Duration(seconds: 3),
    this.alignment = AlignmentDirectional.bottomCenter,
    this.builder,
  });

  /// Notification title
  final String? title;

  /// Notification message Text
  final String message;

  /// Optional [NotificationAction] provides notification with
  /// an action callback
  ///
  /// A [NotificationAction] can be create by
  /// [NotificationAction.button] or [NotificationAction.onTap].
  final NotificationAction? action;

  /// Notification [Icon] widget
  ///
  /// An optional [Icon] widget shown besides the [message].
  final Widget? icon;

  /// Notification background color
  ///
  /// Colors notification body.
  /// If null, defaults to Notification's
  /// [NotificationChannel.defaultBackgroundColor] and if that's not provided
  /// (null value or Unregistered [NotificationChannel]),
  /// [Theme.of(Context).colorScheme.primary].
  final Color? backgroundColor;

  /// Notification foreground color.
  ///
  /// Colors notification texts, icons, progressIndicator, etc.
  /// If null, defaults to Notification Channels default
  /// [NotificationChannel.defaultForegroundColor] and if that's null
  /// [Theme.of(Context).colorScheme.onPrimary].
  final Color? foregroundColor;

  /// Notification dismiss duration
  ///
  /// Defaults to [NotificationConfiguration.dismissDuration].
  final Duration? dismissDuration;

  /// [NotificationWidget] position on the Screen.
  final AlignmentDirectional alignment;

  /// Custom builder for the notification stack indicator.
  final NotificationBuilder? builder;

  /// Copy with overrides for easy partial updates.
  NotificationConfiguration copyWith({
    final String? title,
    final String? message,
    final NotificationAction? action,
    final Widget? icon,
    final AlignmentDirectional? alignment,
    final Color? foregroundColor,
    final Color? backgroundColor,
    final Duration? dismissDuration,
    final BorderRadius? defaultBorderRadius,
    final NotificationBuilder? builder,
  }) =>
      NotificationConfiguration(
        message: message ?? this.message,
        title: title ?? this.title,
        alignment: alignment ?? this.alignment,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        icon: icon ?? this.icon,
        action: action ?? this.action,
        foregroundColor: foregroundColor ?? this.foregroundColor,
        dismissDuration: dismissDuration ?? this.dismissDuration,
        builder: builder ?? this.builder,
      );
}
