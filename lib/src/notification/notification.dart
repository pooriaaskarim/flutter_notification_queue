import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:logd/logd.dart';

import '../../flutter_notification_queue.dart';
import '../utils/utils.dart';

part 'interaction/zones/base.dart';
part 'interaction/zones/edges.dart';
part 'interaction/zones/positions.dart';
part 'interaction/zones/resolvers.dart';
part 'interaction/dismissal_targets.dart';
part 'interaction/draggable_transitions.dart';
part 'interaction/relocation_targets.dart';
part 'notification_action.dart';
part 'theme/notification_theme.dart';
part 'type_defs.dart';

@immutable
class NotificationWidget extends StatefulWidget {
  const NotificationWidget._({
    required final GlobalObjectKey<NotificationWidgetState> key,
    required this.message,
    required this.id,
    required this.queue,
    required this.channelName,
    required this.channel,
    this.title,
    this.action,
    this.icon,
    this.color,
    this.foregroundColor,
    this.backgroundColor,
    this.dismissDuration,
    this.builder,
  }) : _key = key;

  factory NotificationWidget({
    required final String message,
    final String? id,
    final String channelName = 'default',
    final String? title,
    final QueuePosition? position,
    final NotificationAction? action,
    final Widget? icon,
    final Color? color,
    final Color? foregroundColor,
    final Color? backgroundColor,
    final Duration? dismissDuration,
    final NotificationBuilder? builder,
  }) {
    final resolvedId = id ?? DateTime.now().toString();
    final resolvedKey = GlobalObjectKey<NotificationWidgetState>(resolvedId);
    final resolveChannel =
        FlutterNotificationQueue.configuration.getChannel(channelName);
    final resolvedQueue = FlutterNotificationQueue.configuration
        .getQueue(position ?? resolveChannel.position);

    return NotificationWidget._(
      id: resolvedId,
      key: resolvedKey,
      message: message,
      channelName: channelName,
      channel: resolveChannel,
      queue: resolvedQueue,
      title: title,
      action: action,
      icon: icon,
      color: color,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      dismissDuration: dismissDuration,
      builder: builder,
    );
  }

  final GlobalKey<NotificationWidgetState> _key;

  @override
  GlobalKey<NotificationWidgetState> get key => _key;

  /// Optional Notification ID
  ///
  /// A unique [GlobalKey] will be provided for [NotificationWidget]
  /// if [id] is provided or not,
  /// but to have more control over [NotificationWidget], you can
  /// set the [id] and use it.
  final String id;

  /// Name of the notification channel.
  ///
  /// Defaults to the system's default [NotificationChannel] if
  /// [channelName] is not registered.
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

  /// Notification color.
  ///
  /// Colors notification icon, border, and body filled [QueueStyle]s.
  /// If null, defaults to Notification Channels
  /// [NotificationChannel.defaultColor] and if that's null
  /// [Theme.of(Context).colorScheme.primary].
  final Color? color;

  /// Notification foreground color.
  ///
  /// Colors notification texts, close, expand and action buttons
  /// and the progressIndicator.
  /// If null, defaults to Notification Channels
  /// [NotificationChannel.defaultForegroundColor] and if that's null
  /// [Theme.of(Context).colorScheme.onSurface].
  final Color? foregroundColor;

  /// Notification background color
  ///
  /// Colors notification body.
  /// If null, defaults to Notification's
  /// [NotificationChannel.defaultBackgroundColor] and if that's not provided
  /// (null value or Unregistered [NotificationChannel]),
  /// [Theme.of(Context).colorScheme.surface].
  final Color? backgroundColor;

  /// Notification dismiss duration
  ///
  /// If null, [NotificationWidget] will be permanent.
  /// Defaults to [NotificationChannel.defaultDismissDuration] if null.
  //todo: what if a channel is set with a specific Duration but
  //todo:  user wants a specific descendant notification to be permanent?
  //todo: (bool) permanent field for notification or the channel?
  final Duration? dismissDuration;

  final NotificationQueue queue;

  final NotificationChannel channel;

  /// Custom builder for the notification stack indicator.
  final NotificationBuilder? builder;

  void show() => FlutterNotificationQueue.coordinator.queue(this);

  Future<void> dismiss() async {
    final state = key.currentState;
    if (state != null) {
      await state.dismiss();
    } else {
      FlutterNotificationQueue.coordinator.dismiss(this);
    }
  }

  NotificationWidget? relocateTo(final QueuePosition position) =>
      FlutterNotificationQueue.coordinator.relocate(this, position);

  @override
  State<StatefulWidget> createState() => NotificationWidgetState();

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
      ' color: $color,'
      ' dismissDuration: $dismissDuration,'
      ' builder: $builder,)';

  NotificationWidget copyToQueue(
    final NotificationQueue targetQueue,
  ) =>
      NotificationWidget._(
        key: GlobalObjectKey<NotificationWidgetState>(id),
        id: id,
        message: message,
        queue: targetQueue,
        channelName: channelName,
        channel: channel,
        title: title,
        action: action,
        icon: icon,
        color: color,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        dismissDuration: dismissDuration,
        builder: builder,
      );
}

class NotificationWidgetState extends State<NotificationWidget>
    with SingleTickerProviderStateMixin {
  late NotificationTheme theme;

  Duration? get resolvedDismissDuration =>
      widget.dismissDuration ?? widget.channel.defaultDismissDuration;

  bool get hasTitle => widget.title != null;

  bool get hasOnTapAction =>
      widget.action != null &&
      widget.action!.type == NotificationActionType.onTap;

  bool get hasButtonAction =>
      widget.action != null &&
      widget.action!.type == NotificationActionType.button;

  /// Whether user expanded the notification.
  ///
  /// An expanded notification will not be dismissed using [dismissTimer].
  final ValueNotifier<bool> isExpanded = ValueNotifier(false);

  Timer? dismissTimer;

  late final AnimationController animationController;

  static final _logger = Logger.get('fnq.Notification');

  @override
  void initState() {
    _logger.debugBuffer
      ?..writeln('Created State.')
      ..sink();
    super.initState();
    _showCloseButton.value = widget.queue.closeButtonBehavior.initialOpacity;
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      animationBehavior: AnimationBehavior.preserve,
      reverseDuration: const Duration(milliseconds: 240),
    )..forward();

    initDismissTimer();
  }

  @override
  void didChangeDependencies() {
    // widget.state = this;
    theme = NotificationTheme.resolveWith(context, widget.queue.style, widget);
    _logger.debugBuffer
      ?..writeAll([
        'NotificationState: $this',
      ])
      ..sink();

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(final NotificationWidget oldWidget) {
    _logger.debugBuffer
      ?..writeAll(['oldWidget: $oldWidget', 'newWidget: $widget'])
      ..sink();
    super.didUpdateWidget(oldWidget);
  }

  Future<void> dismiss() async {
    await animationController.reverse();
    FlutterNotificationQueue.coordinator.dismiss(widget);
    _logger.debugBuffer
      ?..writeAll(['Dismissed.'])
      ..sink();
  }

  @override
  void dispose() {
    animationController.dispose();
    ditchDismissTimer();
    isExpanded.dispose();
    _logger.debugBuffer
      ?..writeln('Disposed')
      ..sink();

    super.dispose();
  }

  void initDismissTimer() {
    if (resolvedDismissDuration != null) {
      dismissTimer = Timer(resolvedDismissDuration!, () {
        if (mounted && !isExpanded.value) {
          dismiss();
        }
      });
    }
  }

  void ditchDismissTimer() {
    dismissTimer?.cancel();
    dismissTimer = null;
  }

  @override
  Widget build(final BuildContext context) => widget.queue.transition.build(
        context,
        animationController,
        widget.queue.position,
        _buildNotification(),
      );

  Widget _buildNotification() => Directionality(
        textDirection: Utils.estimateDirectionOfText(
          widget.title ?? widget.message,
        ),
        child: ValueListenableBuilder(
          valueListenable: isExpanded,
          builder: (final context, final isExpanded, final child) => ClipRRect(
            borderRadius: theme.borderRadius,
            child: BackdropFilter(
              enabled: theme.opacity < 1.0,
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Material(
                shape: theme.shape,
                borderOnForeground: true,
                type: MaterialType.canvas,
                color: theme.backgroundColor.withValues(alpha: theme.opacity),
                child: MouseRegion(
                  onEnter: (final _) => _showCloseButton.value = widget
                      .queue.closeButtonBehavior
                      .onHover(isHovering: true),
                  onExit: (final _) => _showCloseButton.value = widget
                      .queue.closeButtonBehavior
                      .onHover(isHovering: false),
                  child: InkWell(
                    onTap: !hasOnTapAction
                        ? null
                        : () {
                            widget.action?.onPressed();
                            dismiss();
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      constraints: Utils.horizontalConstraints(context),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        border: theme.border,
                      ),
                      padding: EdgeInsetsDirectional.symmetric(
                        vertical: isExpanded ? 8 : 4,
                        horizontal: 4,
                      ),
                      // padding: EdgeInsets.all(8),
                      child: Column(
                        spacing: 4,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 4,
                            children: [
                              _getExpandButton(isExpanded: isExpanded),
                              Expanded(
                                child: _getTitle(isExpanded: isExpanded),
                              ),
                              _getCloseButton(isExpanded: true),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsetsGeometry.symmetric(
                              horizontal: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 8,
                              children: [
                                IconTheme(
                                  data: IconThemeData(
                                    color: theme.color,
                                    size: 24,
                                  ),
                                  child: widget.icon ??
                                      widget.channel.defaultIcon ??
                                      const SizedBox.shrink(),
                                ),
                                Expanded(
                                  child: Text(
                                    widget.message,
                                    style: theme.themeData.textTheme.bodyMedium
                                        ?.copyWith(
                                      color: theme.foregroundColor,
                                    ),
                                    maxLines: isExpanded ? 10 : 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _getActionButton(),
                          _timerIndicator(isExpanded: isExpanded),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _getTitle({required final bool isExpanded}) => hasTitle
      ? Directionality(
          textDirection: Utils.estimateDirectionOfText(widget.title ?? ''),
          child: Text(
            widget.title ?? '',
            style: theme.themeData.textTheme.titleMedium?.copyWith(
              color: theme.foregroundColor,
              fontWeight: FontWeight.bold,
            ),
            maxLines: isExpanded ? 5 : null,
            overflow: TextOverflow.ellipsis,
          ),
        )
      : const SizedBox.shrink();

  Widget _getActionButton() => hasButtonAction
      ? Container(
          alignment: AlignmentDirectional.centerEnd,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextButton(
            style: ButtonStyle(
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              visualDensity: VisualDensity.compact,
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(4),
                ),
              ),
            ),
            child: Text(
              widget.action!.label!,
              style: theme.themeData.textTheme.labelMedium
                  ?.copyWith(color: theme.foregroundColor),
            ),
            onPressed: () {
              widget.action!.onPressed();
              dismiss();
            },
          ),
        )
      : const SizedBox.shrink();

  Widget _timerIndicator({required final bool isExpanded}) =>
      dismissTimer != null && !isExpanded
          ? TweenAnimationBuilder(
              duration: resolvedDismissDuration!,
              tween: Tween<double>(begin: 0.0, end: 1.0),
              curve: Curves.easeInOut,
              builder: (final context, final animation, final child) => Padding(
                padding: const EdgeInsetsGeometry.only(
                  right: 4,
                  left: 4,
                ),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  valueColor: ColorTween(
                    begin: theme.foregroundColor.withValues(
                      alpha: 0.5,
                    ),
                    end: theme.foregroundColor.withValues(
                      alpha: 0.5,
                    ),
                  ).animate(
                    CurvedAnimation(
                      parent: AlwaysStoppedAnimation(animation),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  backgroundColor: theme.backgroundColor,
                  value: animation,
                ),
              ),
            )
          : const SizedBox.shrink();

  Widget _getExpandButton({required final bool isExpanded}) {
    final expandMoreIcon = (widget.queue is BottomLeftQueue ||
            widget.queue is BottomCenterQueue ||
            widget.queue is BottomRightQueue)
        ? Icons.expand_less
        : Icons.expand_more;
    final expandLessIcon = (widget.queue is BottomLeftQueue ||
            widget.queue is BottomCenterQueue ||
            widget.queue is BottomRightQueue)
        ? Icons.expand_more
        : Icons.expand_less;
    return SizedBox.square(
      dimension: 32,
      child: Center(
        child: IconButton(
          alignment: AlignmentGeometry.center,
          padding: EdgeInsets.zero,
          icon: Icon(
            isExpanded ? expandLessIcon : expandMoreIcon,
            color: theme.foregroundColor,
          ),
          visualDensity: VisualDensity.compact,
          onPressed: () {
            if (isExpanded) {
              initDismissTimer();
            } else {
              ditchDismissTimer();
            }
            this.isExpanded.value = !isExpanded;
          },
        ),
      ),
    );
  }

  final _showCloseButton = ValueNotifier(0.0);

  Widget _getCloseButton({required final bool isExpanded}) => SizedBox.square(
        dimension: 24,
        child: ValueListenableBuilder(
          valueListenable: _showCloseButton,
          builder: (final context, final opacity, final child) => IgnorePointer(
            ignoring: opacity == 0.0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              opacity: opacity,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: dismiss,
                iconSize: 18,
                icon: Icon(
                  Icons.close,
                  color: theme.foregroundColor,
                ),
              ),
            ),
          ),
        ),
      );
}
