part of 'in_app_notification_manager.dart';

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

class InAppNotification extends StatefulWidget {
  const InAppNotification({
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
    super.key,
  }) : assert(
          dismissDuration != null || (action != null),
          'InAppNotification should have an action'
          ' or dismiss after a period of time.',
        );

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
    final Key? key,
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
        key: key,
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
    final Key? key,
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
        key: key,
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
    final Key? key,
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
        key: key,
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
    final Key? key,
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
        key: key,
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
  /// Defaults to ```Theme.of(context).colorScheme.primary```.
  final Color? backgroundColor;

  /// Notification foreground color.
  ///
  /// Colors notification texts.
  /// Defaults to ```Theme.of(context).colorScheme.onPrimary```.
  final Color? foregroundColor;

  /// Notification content Padding
  final EdgeInsetsGeometry? padding;

  /// Whether the Close Button should be shown
  final bool? showCloseIcon;

  /// Notification dismiss duration
  ///
  /// If set to null or  ```Duration.zero```,
  /// [InAppNotification] will be permanent, but a
  /// [InAppNotificationAction] must be provided for user to interact
  /// with [InAppNotification].
  /// Defaults to [_defaultDismissDuration].
  final Duration? dismissDuration;

  /// Whether a non-zero [dismissDuration] is set
  bool get isDismissible =>
      dismissDuration != null && dismissDuration!.inMilliseconds >= 0;

  /// Border Radius of [InAppNotification]
  ///
  /// Defaults to [_defaultBorderRadius]
  final BorderRadius? borderRadius;

  // @override
  // GlobalKey<InAppNotificationState> get key => _key;
  // final _key = GlobalKey<InAppNotificationState>();

  @override
  State<InAppNotification> createState() => InAppNotificationState();
}

class InAppNotificationState extends State<InAppNotification> {
  final InAppNotificationManager _manager = InAppNotificationManager.instance;

  Size? screenSize;
  ThemeData? themeData;
  Color get _resolvedForeground =>
      widget.foregroundColor ??
      themeData?.colorScheme.onPrimary ??
      Colors.white;
  Color get _resolvedBackground =>
      widget.backgroundColor ?? themeData?.colorScheme.primary ?? Colors.black;

  final ValueNotifier<bool> _isHolding = ValueNotifier(false);

  final ValueNotifier<Offset> _holdOffsetNotifier = ValueNotifier(Offset.zero);

  Size? _notificationCardSize;
  final GlobalKey _notificationCardKey = GlobalKey();
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
    final index = _manager._activeNotifications.value.indexOf(widget);
    if (index != -1) {
      debugPrint('''
---InAppNotification---Key:${widget.key}---HashCode:${widget.hashCode}---
---Removing at index $index
''');
      _manager._activeNotifications.value.removeAt(index);
      _manager._activeNotifications.notifyListeners();
      _manager._processQueue(context);
      _dismissTimer?.cancel();
      _dismissTimer = null;
      _isHolding.dispose();
      _holdOffsetNotifier.dispose();

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    themeData = mounted ? Theme.of(context) : null;
    screenSize = mounted ? MediaQuery.of(context).size : null;
    if (mounted) {
      SchedulerBinding.instance.addPostFrameCallback(
        (final _) {
          setState(() {
            _notificationCardSize = (_notificationCardKey.currentContext
                    ?.findRenderObject() as RenderBox?)
                ?.size;
          });
        },
      );
    }
  }

  void _initDismissTimer() {
    if (widget.isDismissible) {
      _dismissTimer = Timer(widget.dismissDuration!, () {
        if (!_isHolding.value) {
          if (mounted) {
            dispose();
          }
        }
      });
    }
  }

  @override
  Widget build(final BuildContext context) => ValueListenableBuilder(
        valueListenable: _holdOffsetNotifier,
        builder: (final context, final holdOffset, final child) {
          final passedVerticalThreshold = holdOffset.dy < 1 ||
              holdOffset.dy > ((screenSize?.height ?? 0) / 2) - 1;
          final passedHorizontalThreshold = holdOffset.dx < 1 ||
              holdOffset.dx > ((screenSize?.width ?? 0) / 2) - 1;
          final passedThreshold =
              passedVerticalThreshold || passedHorizontalThreshold;

          const initialOffset = Offset(0, 0);
          _holdOffsetNotifier.value = initialOffset;

          return GestureDetector(
            onLongPressStart: (final _) => _holdDismiss(),
            onLongPressMoveUpdate: (final details) {
              final updatedOffset = Offset(
                details.localPosition.dx -
                    ((_notificationCardSize?.width ?? 0) / 1.5),
                details.localPosition.dy -
                    ((_notificationCardSize?.height ?? 0) / 1.5),
              );
              _holdOffsetNotifier.value = updatedOffset;
            },
            onLongPressEnd: (final details) {
              if (passedThreshold) {
                if (widget.isDismissible) {
                  dispose();
                  return;
                }
              }
              _holdOffsetNotifier.value = initialOffset;
              _resumeDismiss();
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              opacity: !passedThreshold ? 0.0 : 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                margin: Utils.horizontalPadding(
                  context,
                  largerPaddings: true,
                ).add(
                  const EdgeInsetsGeometry.symmetric(
                    vertical: 4,
                    horizontal: 48,
                  ),
                ),
                transform: Transform.translate(
                  offset: holdOffset,
                ).transform,
                child: Material(
                  key: _notificationCardKey,
                  borderRadius: widget.borderRadius,
                  color: _resolvedBackground.withValues(alpha: _opacity),
                  elevation: _elevation,
                  child: InkWell(
                    borderRadius: widget.borderRadius,
                    onTap: _hasOnTapAction
                        ? () {
                            widget.action!.onPressed();
                            dispose();
                          }
                        : null,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ).add(widget.padding ?? EdgeInsets.zero),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _getTitle,
                              _getContent,
                              if (_hasButtonAction) _getActionButton,
                            ],
                          ),
                        ),
                        _timerIndicator,
                        if (_shouldShowCloseButton)
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
                                  color: _resolvedForeground,
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
        },
      );

  Widget get _timerIndicator => ValueListenableBuilder(
        valueListenable: _isHolding,
        builder: (final context, final isHolding, final child) {
          if (widget.isDismissible && !isHolding) {
            return PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: TweenAnimationBuilder(
                duration: widget.dismissDuration ?? Duration.zero,
                tween: Tween<double>(begin: 0.0, end: 1.0),
                curve: Curves.easeInOut,
                builder: (final context, final value, final child) => Padding(
                  padding: EdgeInsetsGeometry.only(
                    right: (widget.borderRadius?.bottomRight.x ?? 0.0) / 2,
                    left: (widget.borderRadius?.bottomLeft.x ?? 0.0) / 2,
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
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      );

  void _resumeDismiss() {
    _isHolding.value = false;
    _initDismissTimer();
  }

  void _holdDismiss() {
    _isHolding.value = true;
    _dismissTimer?.cancel();
  }

  Widget get _getTitle => _hasTitle
      ? ValueListenableBuilder(
          valueListenable: _isHolding,
          builder: (final context, final isHolding, final child) =>
              Directionality(
            textDirection: Utils.estimateDirectionOfText(widget.title!),
            child: Text(
              widget.title!,
              style: themeData?.textTheme.titleMedium?.copyWith(
                color: _resolvedForeground,
                fontWeight: FontWeight.bold,
              ),
              maxLines: isHolding ? 5 : null,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
      : const SizedBox.shrink();

  Widget get _getContent => Directionality(
        textDirection: Utils.estimateDirectionOfText(widget.message),
        child: Row(
          spacing: 4,
          children: [
            if (_hasIcon)
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: widget.icon,
              ),
            Expanded(
              child: mounted
                  ? ValueListenableBuilder(
                      valueListenable: _isHolding,
                      builder: (final context, final isHolding, final child) =>
                          Text(
                        widget.message,
                        style: themeData?.textTheme.bodyMedium?.copyWith(
                          color: _resolvedForeground,
                        ),
                        maxLines: isHolding ? 10 : null,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );

  Widget get _getActionButton => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: TextButton(
          child: Text(
            widget.action!.label!,
            style: themeData?.textTheme.labelMedium
                ?.copyWith(color: _resolvedForeground),
          ),
          onPressed: () {
            widget.action!.onPressed();
            dispose();
          },
        ),
      );

  bool get _hasTitle => widget.title != null;

  bool get _hasIcon => widget.icon != null;

  bool get _hasOnTapAction =>
      widget.action != null &&
      widget.action!.type == InAppNotificationActionType.onTap;

  bool get _hasButtonAction =>
      widget.action != null &&
      widget.action!.type == InAppNotificationActionType.button;

  bool get _shouldShowCloseButton =>
      widget.isDismissible && ((widget.showCloseIcon ?? false) || kIsWeb);
}
