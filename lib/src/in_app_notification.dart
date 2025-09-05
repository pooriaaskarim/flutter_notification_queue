import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'utils/utils.dart';

import 'in_app_notification_action.dart';

const _defaultDismissDuration = Duration(seconds: 3);

const Color _infoColor = Color(0xFF51B4FA);
const Color _warningColor = Color(0xFFC97726);
const Color _errorColor = Color(0xFFD03333);
const Color _successColor = Color(0xFF2D7513);
const Color _foregroundColor = Colors.white;

const double _opacity = 0.8;
const _elevation = 6.0;
const _defaultBorderRadius = BorderRadius.all(
  Radius.circular(5.0),
);

const double _initialAlignment = -0.9;
const _dismissThreshold = -0.95;

class InAppNotification {
  InAppNotification({
    required this.message,
    this.icon,
    this.title,
    this.action,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = _defaultBorderRadius,
    this.dismissDuration = _defaultDismissDuration,
    this.padding,
    this.showCloseIcon,
  }) : assert(
          dismissDuration != null || (action != null),
          'InAppNotification should have an action'
          ' or dismiss after a period of time.',
        );

  factory InAppNotification.resolve(
    final String type, {
    required final String message,
    final String? title,
    final InAppNotificationAction? action,
    final Duration? dismissDuration = _defaultDismissDuration,
    final EdgeInsetsGeometry? padding,
    final BorderRadius? borderRadius = _defaultBorderRadius,
    final bool? showCloseIcon,
  }) {
    switch (type) {
      case ('notification'):
        return InAppNotification.warning(
          message: message,
          action: action,
          dismissDuration: dismissDuration,
          padding: padding,
          borderRadius: borderRadius,
          showCloseIcon: showCloseIcon,
          title: title,
        );
      case ('success'):
        return InAppNotification.success(
          message: message,
          action: action,
          dismissDuration: dismissDuration,
          padding: padding,
          borderRadius: borderRadius,
          showCloseIcon: showCloseIcon,
          title: title,
        );
      case ('error'):
        return InAppNotification.error(
          message: message,
          action: action,
          dismissDuration: dismissDuration,
          padding: padding,
          borderRadius: borderRadius,
          showCloseIcon: showCloseIcon,
          title: title,
        );
      default:
        return InAppNotification.info(
          message: message,
          action: action,
          dismissDuration: dismissDuration,
          padding: padding,
          borderRadius: borderRadius,
          showCloseIcon: showCloseIcon,
          title: title,
        );
    }
  }

  /// Bootstrap [InAppNotification] with success configuration
  ///
  /// [backgroundColor] is set to [_successColor]
  /// [foregroundColor] is set to [_foregroundColor]
  factory InAppNotification.success({
    required final String message,
    final String? title,
    final InAppNotificationAction? action,
    final Duration? dismissDuration = _defaultDismissDuration,
    final BorderRadius? borderRadius = _defaultBorderRadius,
    final EdgeInsetsGeometry? padding,
    final bool? showCloseIcon,
  }) =>
      InAppNotification(
        backgroundColor: _successColor,
        foregroundColor: _foregroundColor,
        title: title,
        action: action,
        message: message,
        dismissDuration: dismissDuration,
        padding: padding,
        borderRadius: borderRadius,
        showCloseIcon: showCloseIcon,
        icon: const Icon(Icons.check_circle, color: _foregroundColor),
      );

  /// Bootstrap [InAppNotification] with error configuration
  ///
  /// [backgroundColor] is set to [_errorColor]
  /// [foregroundColor] is set to [_foregroundColor]
  factory InAppNotification.error({
    required final String message,
    final String? title,
    final InAppNotificationAction? action,
    final Duration? dismissDuration = _defaultDismissDuration,
    final BorderRadius? borderRadius = _defaultBorderRadius,
    final EdgeInsetsGeometry? padding,
    final bool? showCloseIcon,
  }) =>
      InAppNotification(
        backgroundColor: _errorColor,
        foregroundColor: _foregroundColor,
        title: title,
        action: action,
        message: message,
        dismissDuration: dismissDuration,
        borderRadius: borderRadius,
        padding: padding,
        showCloseIcon: showCloseIcon,
        icon: const Icon(Icons.error, color: _foregroundColor),
      );

  /// Bootstrap [InAppNotification] with warning configuration
  ///
  /// [backgroundColor] is set to [_warningColor]
  /// [foregroundColor] is set to [_foregroundColor]
  factory InAppNotification.warning({
    required final String message,
    final String? title,
    final InAppNotificationAction? action,
    final Duration? dismissDuration = _defaultDismissDuration,
    final BorderRadius? borderRadius = _defaultBorderRadius,
    final EdgeInsetsGeometry? padding,
    final bool? showCloseIcon,
  }) =>
      InAppNotification(
        backgroundColor: _warningColor,
        foregroundColor: _foregroundColor,
        title: title,
        action: action,
        message: message,
        dismissDuration: dismissDuration,
        borderRadius: borderRadius,
        padding: padding,
        showCloseIcon: showCloseIcon,
        icon: const Icon(Icons.warning, color: _foregroundColor),
      );

  /// Bootstrap [InAppNotification] with info configuration
  ///
  /// [backgroundColor] is set to [_infoColor]
  /// [foregroundColor] is set to [_foregroundColor]
  factory InAppNotification.info({
    required final String message,
    final String? title,
    final InAppNotificationAction? action,
    final Duration? dismissDuration = _defaultDismissDuration,
    final BorderRadius? borderRadius = _defaultBorderRadius,
    final EdgeInsetsGeometry? padding,
    final bool? showCloseIcon,
  }) =>
      InAppNotification(
        backgroundColor: _infoColor,
        foregroundColor: _foregroundColor,
        title: title,
        action: action,
        message: message,
        borderRadius: borderRadius,
        dismissDuration: dismissDuration,
        padding: padding,
        showCloseIcon: showCloseIcon,
        icon: const Icon(Icons.info_outline, color: _foregroundColor),
      );

  /// Notification title
  final String? title;

  /// Notification message Text
  final String message;

  /// Notification action of type [InAppNotificationAction]
  final InAppNotificationAction? action;

  /// Notification icon widget
  final Widget? icon;

  /// Notification background color
  ///
  /// Colors notification body.
  /// Defaults to ```Theme.of(context).colorScheme.surface```.
  final Color? backgroundColor;

  /// Notification foreground color.
  ///
  /// Colors notification texts.
  /// Defaults to ```Theme.of(context).colorScheme.onSurface```.
  final Color? foregroundColor;

  /// Notification content Padding
  final EdgeInsetsGeometry? padding;

  /// Whether the Close Button should be shown
  final bool? showCloseIcon;

  /// Notification dismiss duration
  ///
  /// If set to null or less than ```Duration(milliseconds: 500)```,
  /// [InAppNotification] will be permanent, but a
  /// [InAppNotificationAction] must be provided for user to interact
  /// with [InAppNotification].
  /// Defaults to [_defaultDismissDuration].
  final Duration? dismissDuration;

  /// Whether a non-zero [dismissDuration] is set
  bool get _isDismissible =>
      dismissDuration != null && (dismissDuration!.inMilliseconds >= 500);

  /// Border Radius of [InAppNotification]
  ///
  /// Defaults to [_defaultBorderRadius]
  final BorderRadius? borderRadius;

  ValueNotifier<double>? _verticalAlignmentNotifier;
  OverlayEntry? _overlayEntry;
  bool _isHolding = false;
  bool _isShown = false; // Track consumption
  bool _isDisposed = false; // Prevent reuse after dispose

  /// Shows the notification and returns a controller for manual disposal.
  InAppNotificationController show(BuildContext context) {
    if (_isShown || _isDisposed) {
      throw StateError(
          'InAppNotification already shown or disposed. Create a new instance.');
    }
    _isShown = true;

    _overlayEntry = OverlayEntry(builder: (context) => _build(context));
    Overlay.of(context).insert(_overlayEntry!);
    _delayedDismiss();

    return InAppNotificationController._(this);
  }

  Future<void> _delayedDismiss() async {
    if (_isDismissible) {
      await Future.delayed(dismissDuration!).then((final _) {
        if (!_isHolding && !_isDisposed) {
          dispose();
        }
      });
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;

    _verticalAlignmentNotifier?.dispose();
    _verticalAlignmentNotifier = null;
  }

  Widget _build(final BuildContext context) {
    final themeData = Theme.of(context);
    _verticalAlignmentNotifier = ValueNotifier<double>(_initialAlignment);

    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onVerticalDragEnd: !_isDismissible
          ? null
          : (final _) {
              if (_verticalAlignmentNotifier!.value > _dismissThreshold &&
                  _verticalAlignmentNotifier!.value < _initialAlignment) {
                _verticalAlignmentNotifier!.value = _initialAlignment;
              } else {
                dispose();
              }
            },
      onVerticalDragUpdate: !_isDismissible
          ? null
          : (final details) {
              final updatedAlignment = -1 +
                  (details.globalPosition.dy / (screenSize.height / 2)) -
                  .11;
              _verticalAlignmentNotifier!.value =
                  (updatedAlignment > _initialAlignment)
                      ? _initialAlignment
                      : updatedAlignment;
            },
      onLongPressDown: (final _) => _isHolding = true,
      onLongPressEnd: (final _) {
        _isHolding = false;
        _delayedDismiss();
      },
      child: ValueListenableBuilder(
        valueListenable: _verticalAlignmentNotifier!,
        builder: (final context, final verticalAlignmentValue, final _) =>
            Container(
          alignment: Alignment(0, verticalAlignmentValue),
          margin: Utils.horizontalPadding(
            context,
            largerPaddings: true,
          ).add(const EdgeInsets.symmetric(vertical: 8, horizontal: 48)),
          child: Material(
            borderRadius: borderRadius,
            color: (backgroundColor ?? themeData.colorScheme.surface)
                .withValues(alpha: _opacity),
            elevation: _elevation,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: action != null &&
                      action!.type == InAppNotificationActionType.onTap
                  ? () {
                      action!.onPressed();
                      dispose();
                    }
                  : null,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ).add(padding ?? EdgeInsets.zero),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _getTitle(themeData),
                        _getContent(themeData),
                        if (action != null &&
                            action!.type == InAppNotificationActionType.button)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              child: Text(
                                action!.label!,
                                style: themeData.textTheme.labelMedium
                                    ?.copyWith(color: foregroundColor),
                              ),
                              onPressed: () {
                                action!.onPressed();
                                dispose();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_isDismissible && ((showCloseIcon ?? false) || kIsWeb))
                    PositionedDirectional(
                      top: 4,
                      end: 8,
                      child: SizedBox.square(
                        dimension: 16,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: dispose,
                          icon: Icon(
                            Icons.close,
                            color: foregroundColor,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getTitle(final ThemeData themeData) => _hasTitle
      ? Directionality(
          textDirection: Utils.estimateDirectionOfText(title!),
          child: Text(
            title!,
            style: themeData.textTheme.titleMedium?.copyWith(
              color: foregroundColor ?? themeData.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )
      : const SizedBox.shrink();

  Directionality _getContent(final ThemeData themeData) => Directionality(
        textDirection: Utils.estimateDirectionOfText(message),
        child: LayoutBuilder(
          builder: (final _, final constraints) => Row(
            spacing: 4,
            children: [
              if (_hasIcon)
                Container(
                  constraints:
                      BoxConstraints(maxWidth: constraints.maxWidth / 8),
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: icon,
                ),
              Container(
                constraints: BoxConstraints(
                  maxWidth: _hasIcon
                      ? constraints.maxWidth / 1.15
                      : constraints.maxWidth,
                ),
                child: Text(
                  message,
                  style: themeData.textTheme.bodyMedium?.copyWith(
                    color: foregroundColor ?? themeData.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

  bool get _hasTitle => title != null;

  bool get _hasIcon => icon != null;
}

class InAppNotificationController {
  InAppNotificationController._(this._notification);

  final InAppNotification _notification;

  void dismiss() => _notification.dispose();
}

// class InAppNotificationEntry extends OverlayEntry {
//   InAppNotificationEntry({
//     required super.builder,
//     super.opaque,
//     super.maintainState,
//   });
//
//   @override
//   void dispose() {
//     // Custom cleanup here (e.g., dispose notifiers)
//     super.dispose(); // Calls base disposal
//   }
// }
