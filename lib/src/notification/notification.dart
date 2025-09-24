import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../flutter_notification_queue.dart';
import '../utils/utils.dart';

part 'notification_action.dart';
part 'type_defts.dart';

class NotificationWidget extends StatefulWidget {
  NotificationWidget({
    required this.message,
    this.id,
    this.channelName = 'default',
    this.title,
    this.action,
    this.icon,
    this.foregroundColor,
    this.backgroundColor,
    this.dismissDuration,
    this.position,
    this.builder,
  }) : super(key: ValueKey('$channelName.${id ?? UniqueKey()}'));

  /// Optional Notification ID
  ///
  /// A unique [Key] will be provided for [NotificationWidget] if [id] or not,
  /// but to have more control over this specific [NotificationWidget], you can
  /// set the [id] and use it.
  //todo: handle Update On Duplicate Key
  final String? id;

  /// Name of the notification channel.
  ///
  /// Defaults to [NotificationManager]'s default [NotificationChannel] if
  /// [channelName] is not registered in [NotificationManager].
  ///
  final String channelName;

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
  /// If null, [NotificationWidget] will be permanent.
  /// Defaults to [NotificationChannel.defaultDismissDuration] if null.
  //todo: what if user wants this specific notification to be permanent.
  final Duration? dismissDuration;

  /// [NotificationWidget] position on the Screen.
  final QueuePosition? position;

  /// Custom builder for the notification stack indicator.
  final NotificationBuilder? builder;

  //todo: How about these?
  void show(final BuildContext context) =>
      NotificationManager.instance.show(this, context);
  void dismiss(final BuildContext context) =>
      NotificationManager.instance.dismiss(this, context);

  late final NotificationQueue queue;
  late final NotificationChannel channel;

  @override
  State<StatefulWidget> createState() => _NotificationWidgetState();
  @override
  String toString({final DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'NotificationWidget('
      'key: $key,'
      ' channel: $channelName,'
      ' title: $title,'
      ' message: $message,'
      ' action: $action,'
      ' icon: $icon,'
      ' backgroundColor: $backgroundColor,'
      ' foregroundColor: $foregroundColor,'
      ' dismissDuration: $dismissDuration,'
      ' position: $position,'
      ' builder: $builder)';
}

class _NotificationWidgetState extends State<NotificationWidget>
    with SingleTickerProviderStateMixin {
  late ThemeData _themeData;

  Size get _screenSize => MediaQuery.of(context).size;
  double get _screenHeight => _screenSize.height;
  double get _screenWidth => _screenSize.width;

  Color get _resolvedForeground =>
      widget.foregroundColor ??
      widget.channel.defaultForegroundColor ??
      _themeData.colorScheme.onPrimary;
  Color get _resolvedBackground =>
      widget.backgroundColor ??
      widget.channel.defaultBackgroundColor ??
      _themeData.colorScheme.primary;

  double get _opacity => widget.queue.opacity;
  double get _elevation => widget.queue.elevation;

  BorderRadius get _borderRadius =>
      const BorderRadius.all(Radius.circular(4.0));

  Duration? get _resolvedDismissDuration =>
      widget.dismissDuration ?? widget.channel.defaultDismissDuration;

  double get _dismissalThreshold => widget.queue.dismissalThreshold;

  bool get _hasTitle => widget.title != null;

  bool get _hasIcon => widget.icon != null;

  bool get _hasOnTapAction =>
      widget.action != null &&
      widget.action!.type == NotificationActionType.onTap;

  bool get _hasButtonAction =>
      widget.action != null &&
      widget.action!.type == NotificationActionType.button;

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

  Timer? _dismissTimer;

  late final AnimationController _animationController;

  @override
  void initState() {
    debugPrint('''
---------------Notification${widget.key}: initState called---------------''');
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      animationBehavior: AnimationBehavior.preserve,
      reverseDuration: const Duration(milliseconds: 240),
    )..forward();

    // widget.channel =
    //     NotificationManager.instance.getChannel(widget);
    // widget.queue = NotificationManager.instance.getQueue(_resolvedPosition);
    _initDismissTimer();
  }

  @override
  void didChangeDependencies() {
    debugPrint('''
---------------Notification${widget.key}: didChangeDependencies called---------------''');

    _themeData = Theme.of(context);
    super.didChangeDependencies();
  }

  Future<void> dismiss() async {
    await _animationController.reverse();
    NotificationManager.instance.dismiss(widget, context);
    debugPrint('''
---------------Notification${widget.key}::::dismiss---------------
------------------Dismissed.''');
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
    _disposeDismissTimer();
    _isExpanded.dispose();
    _dragOffsetPairNotifier.dispose();
    debugPrint('''
---------------Notification${widget.key}:::dispose---------------
------------------Disposed.
''');
  }

  void _initDismissTimer() {
    if (_resolvedDismissDuration != null) {
      _dismissTimer = Timer(_resolvedDismissDuration!, () {
        if (mounted && !_isExpanded.value) {
          dismiss();
        }
      });
    }
  }

  void _disposeDismissTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
  }

  @override
  Widget build(final BuildContext context) => SlideTransition(
      position: Tween<Offset>(
        begin: Offset(
            0,
            widget.queue.position.verticalDirection == VerticalDirection.down
                ? -1.0
                : 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
          parent: _animationController, curve: Curves.easeInOut)),
      child: FadeTransition(
        opacity: _animationController,
        child: ValueListenableBuilder(
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
                  final passedHorizontalThreshold =
                      currentGlobalOffset.dx < _dismissalThreshold ||
                          currentGlobalOffset.dx >
                              _screenWidth - _dismissalThreshold;

                  final passedThreshold =
                      passedVerticalThreshold || passedHorizontalThreshold;

                  if (passedThreshold) {
                    dismiss();
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
                                dismiss();
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ));

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
                dismiss();
              },
            ),
          ),
        )
      : const SizedBox.shrink();

  Widget _timerIndicator({required final bool isExpanded}) =>
      _dismissTimer != null && !isExpanded
          ? PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: TweenAnimationBuilder(
                duration: _resolvedDismissDuration!,
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

  bool get _hasCloseButton => widget.queue.showCloseButton;

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
                onPressed: dismiss,
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
}
