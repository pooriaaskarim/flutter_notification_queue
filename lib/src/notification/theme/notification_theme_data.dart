// ignore_for_file: comment_references

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../enums/enums.dart';

/// Immutable theme tokens defining colors, shapes, elevation, and typography
/// for notifications.
///
/// [NotificationThemeData] allows channels and notifications to be themed
/// consistently across light and dark modes, adhering to design system tokens.
///
/// It extends [ThemeExtension] so it can be registered globally in
/// [ThemeData.extensions] or configured per [NotificationChannel] and per
/// [AppNotification].
///
/// Use factory constructors like [NotificationThemeData.fromColorScheme] or
/// [NotificationThemeData.fromSeed] to automatically generate cohesive,
/// accessible palettes.
@immutable
class NotificationThemeData extends ThemeExtension<NotificationThemeData> {
  /// Creates an immutable [NotificationThemeData] token bundle.
  const NotificationThemeData({
    final Color? accentColor,
    final Color? color,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.elevation,
    this.shadowColor,
    this.titleTextStyle,
    this.messageTextStyle,
    this.iconTheme,
  }) : accentColor = accentColor ?? color;

  /// Creates a [NotificationThemeData] configured from a Material 3
  /// [ColorScheme].
  factory NotificationThemeData.fromColorScheme(
    final ColorScheme colorScheme, {
    final NotificationPriority priority = NotificationPriority.normal,
  }) {
    final (accent, bg, fg) = switch (priority) {
      NotificationPriority.critical || NotificationPriority.high => (
          colorScheme.error,
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
        ),
      NotificationPriority.low => (
          colorScheme.secondary,
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
        ),
      NotificationPriority.normal => (
          colorScheme.primary,
          colorScheme.surface,
          colorScheme.onSurface,
        ),
    };
    return NotificationThemeData(
      accentColor: accent,
      backgroundColor: bg,
      foregroundColor: fg,
      borderColor: colorScheme.outlineVariant,
      shadowColor: colorScheme.shadow,
    );
  }

  /// Creates a [NotificationThemeData] by deriving a [ColorScheme] from
  /// [seedColor].
  factory NotificationThemeData.fromSeed({
    required final Color seedColor,
    final Brightness brightness = Brightness.light,
    final NotificationPriority priority = NotificationPriority.normal,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return NotificationThemeData.fromColorScheme(scheme, priority: priority);
  }

  /// Preset for success notifications with green accent.
  factory NotificationThemeData.success(final BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NotificationThemeData(
      accentColor: const Color(0xFF2D7512),
      backgroundColor:
          isDark ? const Color(0xFF132210) : const Color(0xFFEDF7ED),
      foregroundColor:
          isDark ? const Color(0xFFB7F5A2) : const Color(0xFF1E4620),
      borderColor: const Color(0xFF2D7512).withValues(alpha: 0.3),
    );
  }

  /// Preset for error notifications with error accent from ambient [Theme].
  factory NotificationThemeData.error(final BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return NotificationThemeData(
      accentColor: scheme.error,
      backgroundColor: scheme.errorContainer,
      foregroundColor: scheme.onErrorContainer,
      borderColor: scheme.error.withValues(alpha: 0.3),
    );
  }

  /// Preset for warning notifications with amber/orange accent.
  factory NotificationThemeData.warning(final BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NotificationThemeData(
      accentColor: const Color(0xFFC97725),
      backgroundColor:
          isDark ? const Color(0xFF2B1D0E) : const Color(0xFFFFF4E5),
      foregroundColor:
          isDark ? const Color(0xFFFFD19A) : const Color(0xFF663C00),
      borderColor: const Color(0xFFC97725).withValues(alpha: 0.3),
    );
  }

  /// Preset for informational notifications with blue accent.
  factory NotificationThemeData.info(final BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NotificationThemeData(
      accentColor: const Color(0xFF51B4F9),
      backgroundColor:
          isDark ? const Color(0xFF0F2231) : const Color(0xFFE8F4FD),
      foregroundColor:
          isDark ? const Color(0xFFBCE1FD) : const Color(0xFF0D3C61),
      borderColor: const Color(0xFF51B4F9).withValues(alpha: 0.3),
    );
  }

  /// Primary accent color used for icons, progress bars, and status borders.
  final Color? accentColor;

  /// Convenience alias for [accentColor].
  Color? get color => accentColor;

  /// Card body surface color.
  final Color? backgroundColor;

  /// Primary text and icon color on top of [backgroundColor].
  final Color? foregroundColor;

  /// Card outline border color.
  final Color? borderColor;

  /// Card outline border stroke width.
  final double? borderWidth;

  /// Card corner border radius.
  final BorderRadiusGeometry? borderRadius;

  /// Shadow elevation depth.
  final double? elevation;

  /// Elevation drop shadow tint.
  final Color? shadowColor;

  /// Typography styling for the header title.
  final TextStyle? titleTextStyle;

  /// Typography styling for the message body.
  final TextStyle? messageTextStyle;

  /// Theme overrides for leading and trailing icons.
  final IconThemeData? iconTheme;

  /// Creates a copy of this [NotificationThemeData] with the given fields
  /// replaced.
  @override
  NotificationThemeData copyWith({
    final Color? accentColor,
    final Color? color,
    final Color? backgroundColor,
    final Color? foregroundColor,
    final Color? borderColor,
    final double? borderWidth,
    final BorderRadiusGeometry? borderRadius,
    final double? elevation,
    final Color? shadowColor,
    final TextStyle? titleTextStyle,
    final TextStyle? messageTextStyle,
    final IconThemeData? iconTheme,
  }) =>
      NotificationThemeData(
        accentColor: accentColor ?? color ?? this.accentColor,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        foregroundColor: foregroundColor ?? this.foregroundColor,
        borderColor: borderColor ?? this.borderColor,
        borderWidth: borderWidth ?? this.borderWidth,
        borderRadius: borderRadius ?? this.borderRadius,
        elevation: elevation ?? this.elevation,
        shadowColor: shadowColor ?? this.shadowColor,
        titleTextStyle: titleTextStyle ?? this.titleTextStyle,
        messageTextStyle: messageTextStyle ?? this.messageTextStyle,
        iconTheme: iconTheme ?? this.iconTheme,
      );

  /// Merges another [NotificationThemeData] onto this instance.
  ///
  /// Any non-null fields in [other] take precedence over this instance's
  /// fields.
  NotificationThemeData merge(final NotificationThemeData? other) {
    if (other == null) {
      return this;
    }
    return copyWith(
      accentColor: other.accentColor,
      backgroundColor: other.backgroundColor,
      foregroundColor: other.foregroundColor,
      borderColor: other.borderColor,
      borderWidth: other.borderWidth,
      borderRadius: other.borderRadius,
      elevation: other.elevation,
      shadowColor: other.shadowColor,
      titleTextStyle: other.titleTextStyle,
      messageTextStyle: other.messageTextStyle,
      iconTheme: other.iconTheme,
    );
  }

  @override
  NotificationThemeData lerp(
    final ThemeExtension<NotificationThemeData>? other,
    final double t,
  ) {
    if (other is! NotificationThemeData) {
      return this;
    }
    return NotificationThemeData(
      accentColor: Color.lerp(accentColor, other.accentColor, t),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      foregroundColor: Color.lerp(foregroundColor, other.foregroundColor, t),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t),
      borderRadius:
          BorderRadiusGeometry.lerp(borderRadius, other.borderRadius, t),
      elevation: lerpDouble(elevation, other.elevation, t),
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t),
      titleTextStyle: TextStyle.lerp(titleTextStyle, other.titleTextStyle, t),
      messageTextStyle:
          TextStyle.lerp(messageTextStyle, other.messageTextStyle, t),
      iconTheme: IconThemeData.lerp(iconTheme, other.iconTheme, t),
    );
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is NotificationThemeData &&
          runtimeType == other.runtimeType &&
          accentColor == other.accentColor &&
          backgroundColor == other.backgroundColor &&
          foregroundColor == other.foregroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          elevation == other.elevation &&
          shadowColor == other.shadowColor &&
          titleTextStyle == other.titleTextStyle &&
          messageTextStyle == other.messageTextStyle &&
          iconTheme == other.iconTheme;

  @override
  int get hashCode => Object.hash(
        accentColor,
        backgroundColor,
        foregroundColor,
        borderColor,
        borderWidth,
        borderRadius,
        elevation,
        shadowColor,
        titleTextStyle,
        messageTextStyle,
        iconTheme,
      );

  @override
  String toString() =>
      'NotificationThemeData(accentColor: $accentColor, '
      'backgroundColor: $backgroundColor, '
      'foregroundColor: $foregroundColor, '
      'elevation: $elevation)';
}
