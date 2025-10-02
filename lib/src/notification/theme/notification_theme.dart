part of '../notification.dart';

class NotificationTheme {
  const NotificationTheme._({
    required this.themeData,
    required this.color,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.shadowColor,
    required this.elevation,
    required this.opacity,
    required this.borderRadius,
    required this.shape,
    required this.border,
  });

  factory NotificationTheme.resolveWith(
    final BuildContext context,
    final QueueStyle style,
    final NotificationWidget notification,
  ) {
    final themeData = Theme.of(context);
    final brightness = themeData.brightness;
    final colorScheme = themeData.colorScheme;

    final Color color;
    final Color backgroundColor;
    final Color foregroundColor;
    final Color shadowColor = themeData.shadowColor;
    final ShapeBorder? shapeBorder;
    final BoxBorder? border;
    final borderRadius = style.borderRadius;
    final elevation = style.elevation;
    final opacity = style.opacity;
    switch (style) {
      case FilledQueueStyle():
        backgroundColor = notification.color ??
            notification.channel.defaultColor ??
            colorScheme.primary;
        color = foregroundColor = (backgroundColor.computeLuminance() > 0.5
            ? Colors.black
            : Colors.white);
        shapeBorder = RoundedSuperellipseBorder(
          borderRadius: borderRadius,
        );
        border = null;
      case OutlinedQueueStyle():
        color = notification.color ??
            notification.channel.defaultColor ??
            colorScheme.primary;
        foregroundColor = notification.foregroundColor ??
            notification.channel.defaultForegroundColor ??
            colorScheme.onSurface;
        backgroundColor = notification.backgroundColor ??
            notification.channel.defaultBackgroundColor ??
            colorScheme.surface;
        shapeBorder = RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(
            color: color,
            width: 2,
          ),
        );
        border = null;

      case FlatQueueStyle():
        color = notification.color ??
            notification.channel.defaultColor ??
            colorScheme.onSurface;
        foregroundColor = notification.foregroundColor ??
            notification.channel.defaultForegroundColor ??
            colorScheme.onSurface;
        backgroundColor = notification.backgroundColor ??
            notification.channel.defaultBackgroundColor ??
            colorScheme.surface;
        shapeBorder = RoundedRectangleBorder(
          borderRadius: borderRadius,
        );
        border = BorderDirectional(
          start: BorderSide(
            color: color,
            width: 4,
          ),
        );
    }
    return NotificationTheme._(
      themeData: themeData,
      color: color,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      shadowColor: shadowColor,
      borderRadius: borderRadius,
      elevation: elevation,
      opacity: opacity,
      border: border,
      shape: shapeBorder,
    );
  }

  final ThemeData themeData;

  /// Notification color.
  ///
  /// Colors icon, borders, filled [QueueStyle]s' background color.
  final Color color;

  /// Notification foreground color.
  ///
  /// Colors notification texts, close, expand and action buttons,
  /// progressIndicator, etc.
  final Color foregroundColor;

  /// Notification background color.
  ///
  /// Colors notification body. Filled styles will ignore this and replace it
  /// with [color].
  final Color backgroundColor;

  /// Notification shadow color.
  //todo: Configurable??!!
  final Color shadowColor;

  final ShapeBorder? shape;
  final BoxBorder? border;
  final double elevation;
  final double opacity;
  final BorderRadiusGeometry borderRadius;
}
