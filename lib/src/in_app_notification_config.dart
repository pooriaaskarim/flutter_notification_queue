import 'package:flutter/material.dart';

import '../in_app_notifications.dart';

/// Configuration for [InAppNotification] and [InAppNotificationManager].
///
/// Customize colors, timings, and behaviors globally or per-instance.
class InAppNotificationConfig {
  const InAppNotificationConfig({
    this.infoColor = const Color(0xFF51B4FA),
    this.warningColor = const Color(0xFFC97726),
    this.errorColor = const Color(0xFFD03333),
    this.successColor = const Color(0xFF2D7513),
    this.foregroundColor = Colors.white,
    this.backgroundColor,
    this.defaultDismissDuration = const Duration(seconds: 3),
    this.position = InAppNotificationPosition.bottomCenter,
    this.opacity = 0.8,
    this.elevation = 6.0,
    this.maxStackSize = 2,
    this.dismissalThreshold = 10.0,
    this.defaultShowCloseButton = false,
    this.stackIndicatorBuilder,
  });

  /// Default color for info notifications.
  final Color infoColor;

  /// Default color for warning notifications.
  final Color warningColor;

  /// Default color for error notifications.
  final Color errorColor;

  /// Default color for success notifications.
  final Color successColor;

  /// Default foreground (text/icon) color for notifications.
  ///
  /// Defaults to [Theme.of(context).colorScheme.onPrimary] if null
  final Color? foregroundColor;

  /// Default background color for notification body.
  ///
  /// Defaults to [Theme.of(context).colorScheme.primary] if null
  final Color? backgroundColor;

  /// Default dismiss duration for temporary notifications.
  final Duration defaultDismissDuration;

  /// Default opacity for notification background.
  final double opacity;

  /// Default elevation for notification cards.
  final double elevation;

  /// Maximum number of active notifications in the stack.
  final int maxStackSize;

  /// Dismissal threshold (pixels) for drag/long-press.
  final double dismissalThreshold;

  /// Whether to show close button.
  final bool defaultShowCloseButton;

  /// [InAppNotification] position on the Screen.
  final InAppNotificationPosition position;

  /// Custom builder for the notification stack indicator.
  final Widget Function(BuildContext context, int queueLength,
      InAppNotificationConfig config)? stackIndicatorBuilder;

  /// Copy with overrides for easy partial updates.
  InAppNotificationConfig copyWith({
    final Color? infoColor,
    final Color? warningColor,
    final Color? errorColor,
    final Color? successColor,
    final Color? foregroundColor,
    final Duration? defaultDismissDuration,
    final BorderRadius? defaultBorderRadius,
    final double? opacity,
    final double? elevation,
    final int? maxStackSize,
    final EdgeInsetsGeometry? defaultContentPadding,
    final double? dismissalThreshold,
    final bool? defaultShowCloseButton,
    final Widget Function(
      BuildContext,
      int,
      InAppNotificationConfig,
    )? stackIndicatorBuilder,
  }) =>
      InAppNotificationConfig(
        infoColor: infoColor ?? this.infoColor,
        warningColor: warningColor ?? this.warningColor,
        errorColor: errorColor ?? this.errorColor,
        successColor: successColor ?? this.successColor,
        foregroundColor: foregroundColor ?? this.foregroundColor,
        defaultDismissDuration:
            defaultDismissDuration ?? this.defaultDismissDuration,
        opacity: opacity ?? this.opacity,
        elevation: elevation ?? this.elevation,
        maxStackSize: maxStackSize ?? this.maxStackSize,
        dismissalThreshold: dismissalThreshold ?? this.dismissalThreshold,
        defaultShowCloseButton:
            defaultShowCloseButton ?? this.defaultShowCloseButton,
        stackIndicatorBuilder:
            stackIndicatorBuilder ?? this.stackIndicatorBuilder,
      );
}

enum InAppNotificationPosition {
  topCenter,
  topStart,
  topEnd,
  bottomCenter,
  bottomStart,
  bottomEnd;

  MainAxisAlignment get mainAxisAlignment {
    switch (this) {
      case InAppNotificationPosition.topCenter:
      case InAppNotificationPosition.topStart:
      case InAppNotificationPosition.topEnd:
        return MainAxisAlignment.start;
      case InAppNotificationPosition.bottomCenter:
      case InAppNotificationPosition.bottomStart:
      case InAppNotificationPosition.bottomEnd:
        return MainAxisAlignment.end;
    }
  }

  CrossAxisAlignment get crossAxisAlignment {
    switch (this) {
      case InAppNotificationPosition.topCenter:
      case InAppNotificationPosition.bottomCenter:
        return CrossAxisAlignment.center;
      case InAppNotificationPosition.topStart:
      case InAppNotificationPosition.bottomStart:
        return CrossAxisAlignment.start;
      case InAppNotificationPosition.topEnd:
      case InAppNotificationPosition.bottomEnd:
        return CrossAxisAlignment.end;
    }
  }

  AlignmentDirectional get alignment {
    switch (this) {
      case InAppNotificationPosition.topCenter:
        return AlignmentDirectional.topCenter;
      case InAppNotificationPosition.topStart:
        return AlignmentDirectional.topStart;
      case InAppNotificationPosition.topEnd:
        return AlignmentDirectional.topEnd;
      case InAppNotificationPosition.bottomCenter:
        return AlignmentDirectional.bottomCenter;
      case InAppNotificationPosition.bottomStart:
        return AlignmentDirectional.bottomStart;
      case InAppNotificationPosition.bottomEnd:
        return AlignmentDirectional.bottomEnd;
    }
  }

  VerticalDirection get verticalDirection {
    switch (this) {
      case InAppNotificationPosition.topCenter:
      case InAppNotificationPosition.topStart:
      case InAppNotificationPosition.topEnd:
        return VerticalDirection.down;
      case InAppNotificationPosition.bottomCenter:
      case InAppNotificationPosition.bottomStart:
      case InAppNotificationPosition.bottomEnd:
        return VerticalDirection.up;
    }
  }
}
