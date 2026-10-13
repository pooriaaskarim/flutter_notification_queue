// ignore_for_file: comment_references

import 'package:flutter/material.dart';

import '../../enums/enums.dart';

/// Immutable theme tokens defining colors, typography, and icons
/// for notifications.
///
/// In accordance with the parametric design system, [color] acts as the
/// primary visual driver for brand and status. How this color is distributed
/// (solid card fill, outline stroke, or leading accent bar) is governed
/// deterministically by the active [QueueStyle] archetype.
///
/// It extends [ThemeExtension] so it can be registered globally in
/// [ThemeData.extensions] or configured per [NotificationChannel] and per
/// [AppNotification].
///
/// Use factory constructors like [NotificationThemeData.fromColorScheme] or
/// [NotificationThemeData.fromSeed] to automatically generate cohesive
/// palettes.
@immutable
class NotificationThemeData extends ThemeExtension<NotificationThemeData> {
  /// Creates an immutable [NotificationThemeData] token bundle.
  const NotificationThemeData({
    this.color,
    this.titleTextStyle,
    this.messageTextStyle,
    this.actionTextStyle,
    this.iconTheme,
  });

  /// Creates a [NotificationThemeData] configured from a Material 3
  /// [ColorScheme].
  factory NotificationThemeData.fromColorScheme(
    final ColorScheme colorScheme, {
    final NotificationPriority priority = NotificationPriority.normal,
  }) {
    final tokenColor = switch (priority) {
      NotificationPriority.critical || NotificationPriority.high =>
        colorScheme.error,
      NotificationPriority.low => colorScheme.secondary,
      NotificationPriority.normal => colorScheme.primary,
    };
    return NotificationThemeData(
      color: tokenColor,
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
  factory NotificationThemeData.success([final BuildContext? _]) =>
      const NotificationThemeData(color: Color(0xFF2D7512));

  /// Preset for error notifications with error accent.
  factory NotificationThemeData.error([final BuildContext? context]) =>
      NotificationThemeData(
        color: context != null
            ? Theme.of(context).colorScheme.error
            : const Color(0xFFD03332),
      );

  /// Preset for warning notifications with amber/orange accent.
  factory NotificationThemeData.warning([final BuildContext? _]) =>
      const NotificationThemeData(color: Color(0xFFC97725));

  /// Preset for informational notifications with blue accent.
  factory NotificationThemeData.info([final BuildContext? _]) =>
      const NotificationThemeData(color: Color(0xFF51B4F9));

  /// Primary color token driving notification status, borders, and fills.
  final Color? color;

  /// Typography styling for the header title.
  final TextStyle? titleTextStyle;

  /// Typography styling for the message body.
  final TextStyle? messageTextStyle;

  /// Typography styling for the action button label.
  final TextStyle? actionTextStyle;

  /// Theme overrides for leading and trailing icons.
  final IconThemeData? iconTheme;

  /// Creates a copy of this [NotificationThemeData] with the given fields
  /// replaced.
  @override
  NotificationThemeData copyWith({
    final Color? color,
    final TextStyle? titleTextStyle,
    final TextStyle? messageTextStyle,
    final TextStyle? actionTextStyle,
    final IconThemeData? iconTheme,
  }) =>
      NotificationThemeData(
        color: color ?? this.color,
        titleTextStyle: titleTextStyle ?? this.titleTextStyle,
        messageTextStyle: messageTextStyle ?? this.messageTextStyle,
        actionTextStyle: actionTextStyle ?? this.actionTextStyle,
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
      color: other.color,
      titleTextStyle: other.titleTextStyle,
      messageTextStyle: other.messageTextStyle,
      actionTextStyle: other.actionTextStyle,
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
      color: Color.lerp(color, other.color, t),
      titleTextStyle: TextStyle.lerp(titleTextStyle, other.titleTextStyle, t),
      messageTextStyle:
          TextStyle.lerp(messageTextStyle, other.messageTextStyle, t),
      actionTextStyle:
          TextStyle.lerp(actionTextStyle, other.actionTextStyle, t),
      iconTheme: IconThemeData.lerp(iconTheme, other.iconTheme, t),
    );
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is NotificationThemeData &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          titleTextStyle == other.titleTextStyle &&
          messageTextStyle == other.messageTextStyle &&
          actionTextStyle == other.actionTextStyle &&
          iconTheme == other.iconTheme;

  @override
  int get hashCode => Object.hash(
        color,
        titleTextStyle,
        messageTextStyle,
        actionTextStyle,
        iconTheme,
      );

  @override
  String toString() => 'NotificationThemeData(color: $color)';
}
