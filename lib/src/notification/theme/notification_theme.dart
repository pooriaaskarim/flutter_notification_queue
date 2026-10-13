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
    this.titleTextStyle,
    this.messageTextStyle,
    this.iconTheme,
    this.theme,
  });

  factory NotificationTheme.resolveWith(
    final BuildContext context,
    final QueueStyle style,
    final NotificationWidget notification,
  ) {
    final themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;
    final ambientExtension = themeData.extension<NotificationThemeData>();

    // 1. Resolve structural Archetype (Style):
    final effectiveStyle = notification.channel.style ?? style;

    // 2. Cascade theme tokens:
    final nTheme = notification.theme;
    final cTheme = notification.channel.theme;

    final tokenAccent = nTheme?.accentColor ??
        cTheme?.accentColor ??
        ambientExtension?.accentColor;
    final tokenBackground = nTheme?.backgroundColor ??
        cTheme?.backgroundColor ??
        ambientExtension?.backgroundColor;
    final tokenForeground = nTheme?.foregroundColor ??
        cTheme?.foregroundColor ??
        ambientExtension?.foregroundColor;
    final tokenBorderColor = nTheme?.borderColor ??
        cTheme?.borderColor ??
        ambientExtension?.borderColor;
    final tokenBorderWidth = nTheme?.borderWidth ??
        cTheme?.borderWidth ??
        ambientExtension?.borderWidth;
    final tokenBorderRadius = nTheme?.borderRadius ??
        cTheme?.borderRadius ??
        ambientExtension?.borderRadius ??
        effectiveStyle.borderRadius;
    final tokenElevation = nTheme?.elevation ??
        cTheme?.elevation ??
        ambientExtension?.elevation ??
        effectiveStyle.elevation;
    final tokenShadowColor = nTheme?.shadowColor ??
        cTheme?.shadowColor ??
        ambientExtension?.shadowColor ??
        themeData.shadowColor;
    final titleTextStyle = nTheme?.titleTextStyle ??
        cTheme?.titleTextStyle ??
        ambientExtension?.titleTextStyle;
    final messageTextStyle = nTheme?.messageTextStyle ??
        cTheme?.messageTextStyle ??
        ambientExtension?.messageTextStyle;
    final iconTheme = nTheme?.iconTheme ??
        cTheme?.iconTheme ??
        ambientExtension?.iconTheme;

    // Fallbacks to deprecated scalar color properties:
    // ignore: deprecated_member_use_from_same_package
    final fallbackColor =
        notification.color ?? notification.channel.defaultColor;
    // ignore: deprecated_member_use_from_same_package
    final fallbackBg = notification.backgroundColor ??
        notification.channel.defaultBackgroundColor;
    // ignore: deprecated_member_use_from_same_package
    final fallbackFg = notification.foregroundColor ??
        notification.channel.defaultForegroundColor;

    final candidateColor = tokenAccent ?? fallbackColor;
    final candidateBg = tokenBackground ?? fallbackBg;
    final candidateFg = tokenForeground ?? fallbackFg;

    final Color color;
    final Color backgroundColor;
    final Color foregroundColor;
    final ShapeBorder? shapeBorder;
    final BoxBorder? border;
    final opacity = effectiveStyle.opacity;

    switch (effectiveStyle) {
      case FilledQueueStyle():
        backgroundColor = candidateBg ?? candidateColor ?? colorScheme.primary;
        color = candidateColor ??
            (backgroundColor.computeLuminance() > 0.5
                ? Colors.black
                : Colors.white);
        foregroundColor = candidateFg ??
            (backgroundColor.computeLuminance() > 0.5
                ? Colors.black
                : Colors.white);
        shapeBorder = tokenBorderColor != null
            ? RoundedSuperellipseBorder(
                borderRadius: tokenBorderRadius,
                side: BorderSide(
                  color: tokenBorderColor,
                  width: tokenBorderWidth ?? 1.0,
                ),
              )
            : RoundedSuperellipseBorder(
                borderRadius: tokenBorderRadius,
              );
        border = null;

      case OutlinedQueueStyle():
        color = candidateColor ?? colorScheme.primary;
        foregroundColor = candidateFg ?? colorScheme.onSurface;
        backgroundColor = candidateBg ?? colorScheme.surface;
        shapeBorder = RoundedRectangleBorder(
          borderRadius: tokenBorderRadius,
          side: BorderSide(
            color: tokenBorderColor ?? color,
            width: tokenBorderWidth ?? 1.0,
          ),
        );
        border = null;

      case FlatQueueStyle():
        color = candidateColor ?? colorScheme.onSurface;
        foregroundColor = candidateFg ?? colorScheme.onSurface;
        backgroundColor = candidateBg ?? colorScheme.surface;
        shapeBorder = RoundedRectangleBorder(
          borderRadius: tokenBorderRadius,
        );
        border = BorderDirectional(
          start: BorderSide(
            color: tokenBorderColor ?? color,
            width: tokenBorderWidth ?? 4,
          ),
        );
    }
    return NotificationTheme._(
      themeData: themeData,
      color: color,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      shadowColor: tokenShadowColor,
      borderRadius: tokenBorderRadius,
      elevation: tokenElevation,
      opacity: opacity,
      border: border,
      shape: shapeBorder,
      titleTextStyle: titleTextStyle,
      messageTextStyle: messageTextStyle,
      iconTheme: iconTheme,
      theme: nTheme ?? cTheme ?? ambientExtension,
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

  /// Notification shadow color, derived from [ThemeData.shadowColor] or tokens.
  final Color shadowColor;

  final ShapeBorder? shape;
  final BoxBorder? border;
  final double elevation;
  final double opacity;
  final BorderRadiusGeometry borderRadius;

  /// Typography styling override for the notification title.
  final TextStyle? titleTextStyle;

  /// Typography styling override for the notification message.
  final TextStyle? messageTextStyle;

  /// Icon theme override for the leading icon.
  final IconThemeData? iconTheme;

  /// Effective [NotificationThemeData] token bundle resolved for this
  /// notification.
  final NotificationThemeData? theme;
}
