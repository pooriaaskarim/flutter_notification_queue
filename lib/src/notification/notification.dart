import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../flutter_notification_queue.dart';
import '../utils/utils.dart';

part 'notification_action.dart';
part 'notification_configuration.dart';
part 'type_defts.dart';

class NotificationWidget extends StatefulWidget {
  const NotificationWidget({
    required UniqueKey super.key,
    required this.configuration,
    this.notificationChannel = 'default',
  });
  final String notificationChannel;

  final NotificationConfiguration configuration;

  @override
  State<StatefulWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  NotificationConfiguration get _notificationConfig => widget.configuration;
  NotificationChannel get _channel =>
      NotificationManager.instance.getNotificationChannel(widget);
  NotificationQueue get _queue => NotificationManager.instance.getQueue(widget);

  Size get _screenSize => MediaQuery.of(context).size;
  double get _screenHeight => _screenSize.height;
  double get _screenWidth => _screenSize.width;

  late ThemeData _themeData;

  Color get _resolvedForeground =>
      _notificationConfig.foregroundColor ??
      _channel.defaultForegroundColor ??
      _themeData.colorScheme.onPrimary;
  Color get _resolvedBackground =>
      _notificationConfig.backgroundColor ??
      _channel.defaultBackgroundColor ??
      _themeData.colorScheme.primary;

  // double get _opacity => _channelConfig.opacity;
  double get _opacity => 0.8;
  // double get _elevation => _channelConfig.elevation;
  double get _elevation => 3;

  BorderRadius get _borderRadius =>
      const BorderRadius.all(Radius.circular(4.0));

  Duration? get _resolvedDismissDuration =>
      _notificationConfig.dismissDuration ?? _channel.defaultDismissDuration;

  double get _dismissalThreshold => _queue.dismissalThreshold;

  bool get _hasTitle => _notificationConfig.title != null;

  bool get _hasIcon => _notificationConfig.icon != null;

  bool get _hasOnTapAction =>
      _notificationConfig.action != null &&
      _notificationConfig.action!.type == NotificationActionType.onTap;

  bool get _hasButtonAction =>
      _notificationConfig.action != null &&
      _notificationConfig.action!.type == NotificationActionType.button;

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
  /// Manages disposal based on [NotificationConfiguration.dismissDuration]
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('''
---Notification---${widget.key}: initState called---''');
    _initDismissTimer();
  }

  @override
  void didChangeDependencies() {
    debugPrint('''
---Notification---${widget.key}: didChangeDependencies called---''');

    _themeData = Theme.of(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
//     debugPrint('''
// ---Notification---${widget.key}: dispose called---''');
//     final index = _instance._activeNotifications.value.indexOf(widget);
//     if (index != -1) {
//       debugPrint('''
// ------${widget.key}: Removed at index $index
// ''');
//       _instance
//         .._activeNotifications.value.removeAt(index)
//         .._activeNotifications.notifyListeners()
//         .._processQueue(context);
//       _disposeDismissTimer();
//       _isExpanded.dispose();
//       _dragOffsetPairNotifier.dispose();
//
//       super.dispose();
//     } else {
//       debugPrint('''
// ------${widget.key}: Skipped removal at index $index
// ''');
//     }
  }

  void _initDismissTimer() {
    if (_resolvedDismissDuration != null) {
      _dismissTimer = Timer(_resolvedDismissDuration!, () {
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
                              _notificationConfig.action!.onPressed();
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
          textDirection:
              Utils.estimateDirectionOfText(_notificationConfig.title ?? ''),
          child: Text(
            _notificationConfig.title ?? '',
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
        textDirection:
            Utils.estimateDirectionOfText(_notificationConfig.message),
        child: Row(
          spacing: 4,
          children: [
            if (_hasIcon) _notificationConfig.icon!,
            Expanded(
              child: Text(
                _notificationConfig.message,
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
            _notificationConfig.message,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              child: Text(
                _notificationConfig.action!.label!,
                style: _themeData.textTheme.labelMedium
                    ?.copyWith(color: _resolvedForeground),
              ),
              onPressed: () {
                _notificationConfig.action!.onPressed();
                dispose();
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
          _notificationConfig.title ?? _notificationConfig.message,
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

  bool get _hasCloseButton => _queue.showCloseButton;

  Widget _getCloseButton() => _hasCloseButton
      ? Directionality(
          textDirection: Utils.estimateDirectionOfText(
            _notificationConfig.title ?? _notificationConfig.message,
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

  bool get _hasPinnedIcon => _notificationConfig.dismissDuration == null;

  Widget _getPinnedIcon() => _hasPinnedIcon
      ? Directionality(
          textDirection: Utils.estimateDirectionOfText(
            _notificationConfig.title ?? _notificationConfig.message,
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
