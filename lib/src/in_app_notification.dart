part of 'in_app_notification_manager.dart';

InAppNotificationConfig get _config => _instance.config;

class InAppNotification extends StatefulWidget {
  const InAppNotification({
    required this.message,
    this.icon,
    this.title,
    this.action,
    this.backgroundColor,
    this.foregroundColor,
    this.dismissDuration,
    this.permanent = false,
    this.showCloseIcon,
    super.key,
  });

  /// Bootstraps [InAppNotification] with success configuration
  ///
  /// [backgroundColor] is set to [InAppNotificationConfig.successColor],
  /// [foregroundColor] is set to [InAppNotificationConfig.foregroundColor].
  factory InAppNotification.success({
    required final String message,
    final String? title,
    final InAppNotificationAction? action,
    final Duration? dismissDuration,
    final bool permanent = false,
    final Key? key,
    final bool? showCloseIcon,
  }) =>
      InAppNotification(
        backgroundColor: _config.successColor,
        foregroundColor: _config.foregroundColor,
        title: title,
        action: action,
        message: message,
        dismissDuration: dismissDuration,
        permanent: permanent,
        showCloseIcon: showCloseIcon,
        icon: Icon(Icons.check_circle, color: _config.foregroundColor),
        key: key,
      );

  /// Bootstraps [InAppNotification] with error configuration
  ///
  /// [backgroundColor] is set to [InAppNotificationConfig.errorColor].
  /// [foregroundColor] is set to [InAppNotificationConfig.foregroundColor].
  factory InAppNotification.error({
    required final String message,
    final String? title,
    final InAppNotificationAction? action,
    final Duration? dismissDuration,
    final bool permanent = false,
    final bool? showCloseIcon,
    final Key? key,
  }) =>
      InAppNotification(
        backgroundColor: _config.errorColor,
        foregroundColor: _config.foregroundColor,
        title: title,
        action: action,
        message: message,
        dismissDuration: dismissDuration,
        permanent: permanent,
        showCloseIcon: showCloseIcon,
        icon: Icon(Icons.error, color: _config.foregroundColor),
        key: key,
      );

  /// Bootstrap [InAppNotification] with warning configuration
  ///
  /// [backgroundColor] is set to [InAppNotificationConfig.warningColor].
  /// [foregroundColor] is set to [InAppNotificationConfig.foregroundColor].
  factory InAppNotification.warning({
    required final String message,
    final String? title,
    final InAppNotificationAction? action,
    final Duration? dismissDuration,
    final bool permanent = false,
    final bool? showCloseIcon,
    final Key? key,
  }) =>
      InAppNotification(
        backgroundColor: _config.warningColor,
        foregroundColor: _config.foregroundColor,
        title: title,
        action: action,
        message: message,
        dismissDuration: dismissDuration,
        permanent: permanent,
        showCloseIcon: showCloseIcon,
        icon: Icon(Icons.warning, color: _config.foregroundColor),
        key: key,
      );

  /// Bootstrap [InAppNotification] with info configuration
  ///
  /// [backgroundColor] is set to [InAppNotificationConfig.infoColor].
  /// [foregroundColor] is set to [InAppNotificationConfig.foregroundColor].
  factory InAppNotification.info({
    required final String message,
    final String? title,
    final InAppNotificationAction? action,
    final Duration? dismissDuration,
    final bool permanent = false,
    final bool? showCloseIcon,
    final Key? key,
  }) =>
      InAppNotification(
        backgroundColor: _config.infoColor,
        foregroundColor: _config.foregroundColor,
        title: title,
        action: action,
        message: message,
        dismissDuration: dismissDuration,
        permanent: permanent,
        showCloseIcon: showCloseIcon,
        icon: Icon(Icons.info_outline, color: _config.foregroundColor),
        key: key,
      );

  /// Notification title
  final String? title;

  /// Notification message Text
  final String message;

  /// Notification action callback of type [InAppNotificationAction]
  ///
  /// A [InAppNotificationAction] can be create by
  /// [InAppNotificationAction.button] or [InAppNotificationAction.onTap].
  /// An action is mandatory for a permanent [InAppNotification] (if
  /// [InAppNotification.dismissDuration] is set to null or  [Duration.zero]).
  final InAppNotificationAction? action;

  /// Notification icon widget
  ///
  /// A [Widget] shown besides the [message].
  final Widget? icon;

  /// Notification background color
  ///
  /// Colors notification body.
  /// Defaults to [InAppNotificationConfig.backgroundColor].
  final Color? backgroundColor;

  /// Notification foreground color.
  ///
  /// Colors notification texts and icons.
  /// Defaults to [InAppNotificationConfig.foregroundColor].
  final Color? foregroundColor;

  /// Whether the Close Button should be shown.
  final bool? showCloseIcon;

  /// Notification dismiss duration
  ///
  /// Defaults to [InAppNotificationConfig.defaultDismissDuration].
  final Duration? dismissDuration;

  /// Whether the notification is *Permanent*
  ///
  /// Skips [InAppNotificationConfig.defaultDismissDuration]
  /// and [dismissDuration] if true.
  final bool permanent;

  @override
  State<InAppNotification> createState() => _InAppNotificationState();
}

class _InAppNotificationState extends State<InAppNotification> {
  Size get _screenSize => MediaQuery.of(context).size;
  double get _screenHeight => _screenSize.height;
  double get _screenWidth => _screenSize.width;

  ThemeData get _themeData => Theme.of(context);
  Color get _resolvedForeground =>
      widget.foregroundColor ??
      _config.foregroundColor ??
      _themeData.colorScheme.onPrimary;
  Color get _resolvedBackground =>
      widget.backgroundColor ??
      _config.backgroundColor ??
      _themeData.colorScheme.primary;

  double get _opacity => _config.opacity;
  double get _elevation => _config.elevation;

  BorderRadius get _borderRadius =>
      const BorderRadius.all(Radius.circular(4.0));

  Duration get _resolvedDismissDuration =>
      widget.dismissDuration ?? _config.defaultDismissDuration;

  double get _dismissalThreshold => _config.dismissalThreshold;

  bool get _hasTitle => widget.title != null;

  bool get _hasIcon => widget.icon != null;

  bool get _hasOnTapAction =>
      widget.action != null &&
      widget.action!.type == InAppNotificationActionType.onTap;

  bool get _hasButtonAction =>
      widget.action != null &&
      widget.action!.type == InAppNotificationActionType.button;

  /// Whether user expanded the notification.
  ///
  /// An expanded notification will not be dismissed using [_dismissTimer].
  final ValueNotifier<bool> _isExpanded = ValueNotifier(false);

  /// An [OffsetPair] to indicate drag input updated
  ///
  /// [OffsetPair.local] is set to drag input of widget,
  /// and [OffsetPair.global] is set to drag input offset in relation
  /// to the screen.
  /// On drag input end, is set to null.
  final ValueNotifier<OffsetPair?> _dragOffsetPairNotifier =
      ValueNotifier(null);

  /// Store the starting position for horizontal drag to calculate
  /// offset from origin.
  Offset? _panDragStartPosition;

  /// Dismiss Timer
  ///
  /// Manages disposal based on [InAppNotification.dismissDuration]
  /// and [InAppNotification.permanent].
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    _initDismissTimer();
  }

  @override
  void dispose() {
    debugPrint('''
---InAppNotification---Key:${widget.key}---HashCode:${widget.hashCode}---
---Trying to Dispose
''');
    final index = _instance._activeNotifications.value.indexOf(widget);
    if (index != -1) {
      debugPrint('''
---InAppNotification---Key:${widget.key}---HashCode:${widget.hashCode}---
---Removing at index $index
''');
      _instance
        .._activeNotifications.value.removeAt(index)
        .._activeNotifications.notifyListeners()
        .._processQueue(context);
      _dismissTimer?.cancel();
      _dismissTimer = null;
      _isExpanded.dispose();
      _dragOffsetPairNotifier.dispose();

      super.dispose();
    } else {
      debugPrint('''
---InAppNotification---Key:${widget.key}---HashCode:${widget.hashCode}---
---Skipping removal at index $index
''');
    }
  }

  @override
  void setState(final VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void _initDismissTimer() {
    if (!widget.permanent) {
      _dismissTimer = Timer(_resolvedDismissDuration, () {
        if (mounted && !_isExpanded.value) {
          dispose();
        }
      });
    }
  }

  void _disposeDismissTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
  }

  @override
  Widget build(final BuildContext context) => ValueListenableBuilder(
        valueListenable: _dragOffsetPairNotifier,
        builder: (final context, final dragOffsetPair, final child) {
          final passedVerticalThreshold = dragOffsetPair != null &&
              (dragOffsetPair.global.dy < _dismissalThreshold ||
                  dragOffsetPair.global.dy >
                      _screenHeight - _dismissalThreshold);
          final passedHorizontalThreshold = dragOffsetPair != null &&
              (dragOffsetPair.global.dx < _dismissalThreshold ||
                  dragOffsetPair.global.dx >
                      _screenWidth - _dismissalThreshold);

          final passedThreshold =
              passedVerticalThreshold || passedHorizontalThreshold;

          return GestureDetector(
            onPanStart: (final details) {
              _panDragStartPosition = details.globalPosition;
              _disposeDismissTimer();
            },
            onPanUpdate: (final details) {
              if (_panDragStartPosition != null) {
                final offsetFromOrigin =
                    details.globalPosition - _panDragStartPosition!;
                _dragOffsetPairNotifier.value = OffsetPair(
                  local: offsetFromOrigin,
                  global: details.globalPosition,
                );
              }
            },
            onPanEnd: (final details) {
              final currentGlobalOffset = dragOffsetPair?.global;
              if (currentGlobalOffset != null) {
                final passedVerticalThreshold =
                    currentGlobalOffset.dy < _dismissalThreshold ||
                        currentGlobalOffset.dy >
                            _screenHeight - _dismissalThreshold;
                final passedHorizontalThreshold = currentGlobalOffset.dx <
                        _dismissalThreshold ||
                    currentGlobalOffset.dx > _screenWidth - _dismissalThreshold;

                final passedThreshold =
                    passedVerticalThreshold || passedHorizontalThreshold;

                if (passedThreshold) {
                  dispose();
                  return;
                }
              }

              _dragOffsetPairNotifier.value = null;
              _panDragStartPosition = null;
              _initDismissTimer();
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 480),
              curve: Curves.easeOut,
              opacity: passedThreshold ? 0.0 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                transform: dragOffsetPair == null
                    ? null
                    : Transform.translate(
                        offset: dragOffsetPair.local,
                      ).transform,
                margin: const EdgeInsetsGeometry.symmetric(
                  vertical: 8,
                  horizontal: 48,
                ),
                constraints: Utils.horizontalConstraints(context),
                child: ValueListenableBuilder(
                  valueListenable: _isExpanded,
                  builder: (final context, final isExpanded, final child) =>
                      Material(
                    borderRadius: _borderRadius,
                    color: _resolvedBackground.withValues(alpha: _opacity),
                    elevation: _elevation,
                    child: InkWell(
                      borderRadius: _borderRadius,
                      onTap: _hasOnTapAction
                          ? () {
                              widget.action!.onPressed();
                              dispose();
                            }
                          : null,
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            padding: EdgeInsets.symmetric(
                              vertical: isExpanded ? 16 : 8,
                              horizontal: 36,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _getTitle(isExpanded: isExpanded),
                                _getContent(isExpanded: isExpanded),
                                _getActionButton(),
                              ],
                            ),
                          ),
                          _timerIndicator(isExpanded: isExpanded),
                          _getExpandButton(isExpanded: isExpanded),
                          _getCloseButton(),
                          if (!isExpanded) _getPinnedIcon(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

  Widget _getTitle({required final bool isExpanded}) => _hasTitle
      ? Directionality(
          textDirection: Utils.estimateDirectionOfText(widget.title ?? ''),
          child: Text(
            widget.title ?? '',
            style: _themeData.textTheme.titleMedium?.copyWith(
              color: _resolvedForeground,
              fontWeight: FontWeight.bold,
            ),
            maxLines: isExpanded ? 5 : null,
            overflow: TextOverflow.ellipsis,
          ),
        )
      : const SizedBox.shrink();

  Widget _getContent({required final bool isExpanded}) => Directionality(
        textDirection: Utils.estimateDirectionOfText(widget.message),
        child: Row(
          spacing: 4,
          children: [
            if (_hasIcon) widget.icon!,
            Expanded(
              child: Text(
                widget.message,
                style: _themeData.textTheme.bodyMedium?.copyWith(
                  color: _resolvedForeground,
                ),
                maxLines: isExpanded ? 10 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _getActionButton() => _hasButtonAction
      ? Directionality(
          textDirection: Utils.estimateDirectionOfText(
            widget.message,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              child: Text(
                widget.action!.label!,
                style: _themeData.textTheme.labelMedium
                    ?.copyWith(color: _resolvedForeground),
              ),
              onPressed: () {
                widget.action!.onPressed();
                dispose();
              },
            ),
          ),
        )
      : const SizedBox.shrink();

  Widget _timerIndicator({required final bool isExpanded}) =>
      !widget.permanent && _dismissTimer != null && !isExpanded
          ? PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: TweenAnimationBuilder(
                duration: _resolvedDismissDuration,
                tween: Tween<double>(begin: 0.0, end: 1.0),
                curve: Curves.easeInOut,
                builder: (final context, final value, final child) => Padding(
                  padding: const EdgeInsetsGeometry.only(
                    right: 4,
                    left: 4,
                  ),
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    valueColor: ColorTween(
                      begin: _resolvedForeground.withValues(
                        alpha: 0.3,
                      ),
                      end: _resolvedForeground.withValues(
                        alpha: _opacity,
                      ),
                    ).animate(
                      CurvedAnimation(
                        parent: AlwaysStoppedAnimation(value),
                        curve: Curves.easeInOut,
                      ),
                    ),
                    backgroundColor: _resolvedBackground,
                    value: value,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink();

  Widget _getExpandButton({required final bool isExpanded}) => Directionality(
        textDirection: Utils.estimateDirectionOfText(
          widget.title ?? widget.message,
        ),
        child: AnimatedPositionedDirectional(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOut,
          top: isExpanded ? 8 : 0,
          bottom: isExpanded ? null : 0,
          start: 0,
          child: Center(
            child: IconButton(
              icon: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: _resolvedForeground,
              ),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4.0),
              onPressed: () {
                if (isExpanded) {
                  _initDismissTimer();
                } else {
                  _disposeDismissTimer();
                }
                _isExpanded.value = !isExpanded;
              },
            ),
          ),
        ),
      );

  bool get _hasCloseButton =>
      (widget.showCloseIcon ?? false) || _config.defaultShowCloseButton;

  Widget _getCloseButton() => _hasCloseButton
      ? Directionality(
          textDirection: Utils.estimateDirectionOfText(
            widget.title ?? widget.message,
          ),
          child: PositionedDirectional(
            top: 8,
            end: 4,
            child: SizedBox.square(
              dimension: 16,
              child: IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: dispose,
                icon: Icon(
                  Icons.close,
                  color: _resolvedForeground,
                  size: 16,
                ),
              ),
            ),
          ),
        )
      : const SizedBox.shrink();

  bool get _hasPinnedIcon => widget.permanent;

  Widget _getPinnedIcon() => _hasPinnedIcon
      ? Directionality(
          textDirection: Utils.estimateDirectionOfText(
            widget.title ?? widget.message,
          ),
          child: PositionedDirectional(
            top: 8,
            start: 4,
            child: SizedBox.square(
              dimension: 16,
              child: Icon(
                const IconData(
                  0xe4f4,
                  fontFamily: 'MaterialIcons',
                ),
                color: _resolvedForeground,
                size: 16,
              ),
            ),
          ),
        )
      : const SizedBox.shrink();
}
