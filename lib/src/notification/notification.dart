import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:logd/logd.dart';
import 'package:meta/meta.dart';

import '../core/core.dart';
import '../enums/enums.dart';
import '../models/offset_pair.dart';
import '../notification_channel/notification_channel.dart';
import '../notification_queue/notification_queue.dart';
import '../types/type_defs.dart';
import '../utils/utils.dart';

part 'app_notification.dart';
part 'interaction/drag_gesture_context.dart';
part 'interaction/gesture_state_machine.dart';
part 'interaction/overlays/dismissal_targets.dart';
part 'interaction/overlays/intent_targets.dart';
part 'interaction/overlays/relocation_targets.dart';
part 'interaction/overlays/reorder_targets.dart';
part 'interaction/plugins/archive.dart';
part 'interaction/plugins/base.dart';
part 'interaction/plugins/custom_action.dart';
part 'interaction/plugins/dismiss.dart';
part 'interaction/plugins/pin.dart';
part 'interaction/plugins/relocate.dart';
part 'interaction/plugins/reorder.dart';
part 'interaction/plugins/reorder_relocate.dart';
part 'interaction/plugins/resolver.dart';
part 'interaction/plugins/snooze.dart';
part 'interaction/widgets/draggable_transitions.dart';
part 'interaction/widgets/feedback_overlays.dart';
part 'interaction/zones/base.dart';
part 'interaction/zones/edges.dart';
part 'interaction/zones/positions.dart';
part 'interaction/zones/resolvers.dart';
part 'interaction/zones/slots.dart';
part 'notification_action.dart';
part 'theme/notification_theme.dart';


/// A widget representing an individual notification card in a queue.
///
/// [NotificationWidget] encapsulates the content (title, message, icon),
/// visual style overrides (colors), behavior overrides (tap, drag), and
/// metadata (priority, groupKey) for a single notification.
///
/// To display a notification, construct a [NotificationWidget] and call [show]:
/// ```dart
/// NotificationWidget(
///   message: 'Successfully saved settings',
///   channelName: 'success',
/// ).show();
/// ```
@immutable
class NotificationWidget extends StatefulWidget {
  /// Creates a new [NotificationWidget] with the specified content and style
  /// overrides.
  ///
  /// The [message] is required and represents the main text of the
  /// notification.
  ///
  /// Use [channelName] to apply defaults from a registered
  /// [NotificationChannel].
  ///
  /// Override settings like [tapBehavior], [dragBehavior], [dismissDuration],
  /// [color], [backgroundColor], and [foregroundColor] to customize the card's
  /// appearance and behavior.
  ///
  /// Set [permanent] to true to prevent the card from auto-dismissing.
  factory NotificationWidget({
    required final String message,
    final String? id,
    final String channelName = 'default',
    final String? title,
    final QueuePosition? position,
    final NotificationAction? action,
    final TapBehavior? tapBehavior,
    final DragBehavior? dragBehavior,
    final LongPressDragBehavior? longPressDragBehavior,
    final Widget? icon,
    final Color? color,
    final Color? foregroundColor,
    final Color? backgroundColor,
    final Duration? dismissDuration,
    final bool permanent = false,
    final NotificationBuilder? builder,
    final NotificationPriority? priority,
    final bool initialIsPinned = false,
    final DateTime? snoozedAt,
    final String? groupKey,
    final ConfigurationManager? configuration,
    final QueueCoordinator? coordinator,
  }) {
    assert(
      dismissDuration == null || dismissDuration > Duration.zero,
      'dismissDuration must be positive or null. '
      'Use permanent: true to keep a notification on screen indefinitely.',
    );
    final config = configuration ??
        coordinator?.configuration ??
        FlutterNotificationQueue.configuration;
    final resolvedId =
        id ?? 'notif_${_idCounter++}_${DateTime.now().microsecondsSinceEpoch}';
    final resolvedKey = GlobalObjectKey<NotificationWidgetState>(resolvedId);
    final resolveChannel = config.getChannel(channelName);
    final effectivePosition = position ??
        config.getEffectiveChannelPosition(channelName) ??
        resolveChannel.position;
    final resolvedQueue = config.getQueue(effectivePosition);

    // permanent: true forces null dismiss duration regardless of channel
    // default, allowing a single notification to opt out of auto-dismiss.
    final resolvedDismissDuration = permanent ? null : dismissDuration;

    return NotificationWidget._(
      id: resolvedId,
      key: resolvedKey,
      message: message,
      channelName: channelName,
      channel: resolveChannel,
      queue: resolvedQueue,
      title: title,
      action: action,
      tapBehavior: tapBehavior,
      dragBehavior: dragBehavior,
      longPressDragBehavior: longPressDragBehavior,
      icon: icon,
      color: color,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      dismissDuration: resolvedDismissDuration,
      builder: builder,
      priority: priority,
      initialIsPinned: initialIsPinned,
      snoozedAt: snoozedAt,
      groupKey: groupKey,
      coordinator: coordinator,
    );
  }
  NotificationWidget._({
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
    this.tapBehavior,
    this.dragBehavior,
    this.longPressDragBehavior,
    this.builder,
    this.priority,
    final bool initialIsPinned = false,
    this.snoozedAt,
    final DateTime? createdAt,
    this.groupKey,
    this.coordinator,
  })  : _key = key,
        isPinnedNotifier = ValueNotifier<bool>(initialIsPinned),
        createdAt = createdAt ?? DateTime.now();

  /// Gets the effective [QueueCoordinator] for this notification.
  QueueCoordinator get effectiveCoordinator =>
      coordinator ?? FlutterNotificationQueue.coordinator;

  static int _idCounter = 0;

  final GlobalKey<NotificationWidgetState> _key;

  @override
  GlobalKey<NotificationWidgetState> get key => _key;

  /// ValueNotifier tracking the pinned status of this notification.
  final ValueNotifier<bool> isPinnedNotifier;

  /// Whether this notification is currently pinned.
  bool get isPinned => isPinnedNotifier.value;
  set isPinned(final bool value) => isPinnedNotifier.value = value;

  /// The timestamp when this notification was snoozed, if any.
  final DateTime? snoozedAt;

  /// The timestamp when this notification was created.
  final DateTime createdAt;

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

  /// Optional group key for bundling notifications. If null, falls back to
  /// [channelName].
  final String? groupKey;

  /// The resolved group key, falling back to [channelName] if null.
  String get resolvedGroupKey => groupKey ?? channelName;

  /// Notification title
  final String? title;

  /// Notification message Text
  final String message;

  /// Optional [NotificationAction] provides notification with
  /// an action callback
  ///
  /// A [NotificationAction] can be created by
  /// [NotificationAction.button] or [NotificationAction.onTap].
  final NotificationAction? action;

  /// Per-notification override for the tap behavior.
  ///
  /// When set, this takes precedence over the queue's
  /// [NotificationQueue.tapBehavior]. When null, the queue-level
  /// behavior is used.
  ///
  /// Example — make a single notification show a detail sheet on tap:
  /// ```dart
  /// NotificationWidget(
  ///   message: 'New message from Alice',
  ///   tapBehavior: TapToAct(
  ///     onTap: (n) => showDetailSheet(n),
  ///   ),
  /// )
  /// ```
  final TapBehavior? tapBehavior;

  /// Per-notification override for the drag behavior.
  final DragBehavior? dragBehavior;

  /// Per-notification override for the long-press drag behavior.
  final LongPressDragBehavior? longPressDragBehavior;

  /// Semantic priority rank override for this notification.
  ///
  /// When set, this takes precedence over the channel's default priority.
  final NotificationPriority? priority;

  /// The resolved priority level, falling back to channel default.
  NotificationPriority get resolvedPriority =>
      priority ?? channel.defaultPriority;

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

  /// The [QueueCoordinator] driving this notification instance.
  final QueueCoordinator? coordinator;

  void show() => effectiveCoordinator.queue(this);

  Future<void> dismiss() async {
    final state = key.currentState;
    if (state != null) {
      await state.dismiss(reason: DismissReason.programmatic);
    } else {
      effectiveCoordinator.dismissWidget(
        this,
        reason: DismissReason.programmatic,
      );
    }
  }

  NotificationWidget? relocateTo(final QueuePosition position) =>
      effectiveCoordinator.relocateWidget(this, position);

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
      ' tapBehavior: $tapBehavior,'
      ' dragBehavior: $dragBehavior,'
      ' longPressDragBehavior: $longPressDragBehavior,'
      ' priority: $priority,'
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
        tapBehavior: tapBehavior,
        dragBehavior: dragBehavior,
        longPressDragBehavior: longPressDragBehavior,
        icon: icon,
        color: color,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        dismissDuration: dismissDuration,
        builder: builder,
        priority: priority,
        initialIsPinned: isPinned,
        snoozedAt: snoozedAt,
        createdAt: createdAt,
        groupKey: groupKey,
        coordinator: coordinator,
      );

  NotificationWidget copyForRequeue({
    final DateTime? snoozedAt,
  }) =>
      NotificationWidget._(
        key: GlobalObjectKey<NotificationWidgetState>(id),
        id: id,
        message: message,
        queue: queue,
        channelName: channelName,
        channel: channel,
        title: title,
        action: action,
        tapBehavior: tapBehavior,
        dragBehavior: dragBehavior,
        longPressDragBehavior: longPressDragBehavior,
        icon: icon,
        color: color,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        dismissDuration: dismissDuration,
        builder: builder,
        priority: priority,
        initialIsPinned: isPinned,
        snoozedAt: snoozedAt,
        createdAt: createdAt,
        groupKey: groupKey,
        coordinator: coordinator,
      );
}

/// The active state of a [NotificationWidget].
///
/// This state manages the notification's lifecycle, gesture detection, timers,
/// and entrance/exit transitions.
class NotificationWidgetState extends State<NotificationWidget>
    with TickerProviderStateMixin {
  late NotificationTheme theme;

  /// Caches the brightness last used to resolve the theme so that
  /// [didChangeDependencies] can skip re-resolving on every inherited
  /// widget change that does not affect colours (e.g. window resize).
  Brightness? _lastBrightness;

  Duration? get resolvedDismissDuration => widget.isPinned
      ? null
      : (widget.dismissDuration ?? widget.channel.defaultDismissDuration);

  bool get hasTitle => widget.title != null;

  bool get hasOnTapAction =>
      widget.action != null &&
      widget.action!.type == NotificationActionType.onTap;

  bool get hasButtonAction =>
      widget.action != null &&
      widget.action!.type == NotificationActionType.button;

  /// Resolves the effective tap behavior for this notification.
  ///
  /// The notification's own [NotificationWidget.tapBehavior] takes precedence
  /// over the queue-level [NotificationQueue.tapBehavior].
  ///
  /// Legacy [NotificationAction.onTap] is respected if no explicit
  /// [TapBehavior] is set, for backward compatibility.
  TapBehavior get _resolvedTapBehavior {
    // 1. Per-notification override wins.
    if (widget.tapBehavior != null) {
      return widget.tapBehavior!;
    }
    // 2. Legacy NotificationAction.onTap shim — preserve old behavior.
    if (hasOnTapAction) {
      return const TapToDismiss();
    }
    // 3. Queue-level default.
    return widget.queue.tapBehavior;
  }

  /// Whether user expanded the notification.
  ///
  /// An expanded notification will not be dismissed using [dismissTimer].
  final ValueNotifier<bool> isExpanded = ValueNotifier(false);

  AnimationController? _dismissProgressController;
  bool _isMouseHovering = false;
  static final Timer _dummyTimer = Timer(Duration.zero, () {});
  Timer? get dismissTimer =>
      _dismissProgressController != null ? _dummyTimer : null;

  late final AnimationController animationController;

  static final _logger = Logger.get('fnq.Notification');

  @override
  void initState() {
    _logger.debugBuffer
      ?..writeln('Created State.')
      ..sink();
    super.initState();
    _showCloseButton.value = widget.queue.closeButtonBehavior.initialOpacity;
    // NOTE: The entry/exit animation for this notification is driven by the
    // QueueWidget's item-level AnimationController (via
    // QueueWidget._buildItem).
    // This controller is intentionally NOT forwarded here to avoid a
    // redundant active ticker that would block pumpAndSettle() in tests.
    // It is kept as a TickerProvider placeholder and may be used for future
    // internal animations.
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      animationBehavior: AnimationBehavior.preserve,
      reverseDuration: const Duration(milliseconds: 240),
    )..value = 1.0;

    widget.isPinnedNotifier.addListener(_handlePinChanged);
    initDismissTimer();
  }

  @override
  void didChangeDependencies() {
    // Only re-resolve the theme when the platform brightness actually
    // changes. Skipping on every inherited-widget notification prevents
    // a full NotificationTheme reconstruction on each resize frame.
    final brightness = Theme.of(context).brightness;
    if (brightness != _lastBrightness) {
      _lastBrightness = brightness;
      theme = NotificationTheme.resolveWith(
        context,
        widget.queue.style,
        widget,
      );
    }
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
    if (oldWidget.isPinnedNotifier != widget.isPinnedNotifier) {
      oldWidget.isPinnedNotifier.removeListener(_handlePinChanged);
      widget.isPinnedNotifier.addListener(_handlePinChanged);
    }
  }

  void _handlePinChanged() {
    if (widget.isPinned) {
      ditchDismissTimer();
    } else {
      initDismissTimer();
    }
  }

  QueueCoordinator get coordinator =>
      widget.coordinator ??
      NotificationScope.maybeCoordinatorOf(context) ??
      FlutterNotificationQueue.coordinator;

  Future<void> dismiss({
    final DismissReason reason = DismissReason.programmatic,
  }) async {
    await animationController.reverse();
    coordinator.dismissWidget(widget, reason: reason);
    _logger.debugBuffer
      ?..writeAll(['Dismissed.'])
      ..sink();
  }

  @override
  void dispose() {
    widget.isPinnedNotifier.removeListener(_handlePinChanged);
    animationController.dispose();
    _dismissProgressController?.dispose();
    isExpanded.dispose();
    _logger.debugBuffer
      ?..writeln('Disposed')
      ..sink();

    super.dispose();
  }

  void initDismissTimer() {
    if (resolvedDismissDuration != null) {
      if (_dismissProgressController == null) {
        _dismissProgressController = AnimationController(
          vsync: this,
          duration: resolvedDismissDuration,
        );
        _dismissProgressController!.addStatusListener((final status) {
          if (status == AnimationStatus.completed) {
            if (mounted && !isExpanded.value) {
              dismiss(reason: DismissReason.timeout);
            }
          }
        });
      } else {
        _dismissProgressController!.duration = resolvedDismissDuration;
      }
      _dismissProgressController!.reset();
      _dismissProgressController!.forward();
    }
  }

  void ditchDismissTimer() {
    _dismissProgressController?.stop(canceled: false);
    _dismissProgressController?.dispose();
    _dismissProgressController = null;
  }

  void _toggleExpanded() {
    isExpanded.value = !isExpanded.value;

    if (isExpanded.value) {
      _dismissProgressController?.stop(canceled: false);
    } else if (!_isMouseHovering) {
      _dismissProgressController?.forward();
    }
  }

  @override
  // The transition animation is already applied by QueueWidget._buildItem using
  // the queue-level item AnimationController. Applying it again here would
  // create a double-transition and an extra active ticker that hangs tests.
  Widget build(final BuildContext context) => _buildNotification();

  Widget _buildNotification() => Directionality(
        textDirection: Utils.estimateDirectionOfText(
          widget.title ?? widget.message,
        ),
        child: ValueListenableBuilder(
          valueListenable: isExpanded,
          builder: (final context, final isExpanded, final child) {
            final useBlur = theme.opacity < 1.0;
            final content = Material(
              shape: theme.shape,
              borderOnForeground: true,
              type: MaterialType.canvas,
              color: theme.backgroundColor.withValues(alpha: theme.opacity),
              child: Listener(
                onPointerDown: (final _) {
                  _dismissProgressController?.stop(canceled: false);
                },
                onPointerUp: (final _) {
                  if (!_isMouseHovering && !isExpanded) {
                    _dismissProgressController?.forward();
                  }
                },
                child: MouseRegion(
                  onEnter: (final _) {
                    _isMouseHovering = true;
                    _showCloseButton.value = widget.queue.closeButtonBehavior
                        .onHover(isHovering: true);
                    _dismissProgressController?.stop(canceled: false);
                  },
                  onExit: (final _) {
                    _isMouseHovering = false;
                    _showCloseButton.value = widget.queue.closeButtonBehavior
                        .onHover(isHovering: false);
                    if (!isExpanded) {
                      _dismissProgressController?.forward();
                    }
                  },
                  child: InkWell(
                    onTap: switch (_resolvedTapBehavior) {
                      TapDisabled() =>
                        () {}, // Intercept tap to prevent drag FSM reset
                      TapToDismiss() => () {
                          coordinator.emitTapped(
                            notification: widget,
                            behavior: _resolvedTapBehavior,
                          );
                          // Legacy onTap action callback respected.
                          if (hasOnTapAction) {
                            widget.action?.onPressed();
                          }
                          dismiss(reason: DismissReason.userTap);
                        },
                      TapToExpand() => () {
                          coordinator.emitTapped(
                            notification: widget,
                            behavior: _resolvedTapBehavior,
                          );
                          _toggleExpanded();
                        },
                      TapToAct(:final onTap, :final dismissOnAct) => () {
                          coordinator.emitTapped(
                            notification: widget,
                            behavior: _resolvedTapBehavior,
                          );
                          onTap();
                          if (dismissOnAct) {
                            dismiss(reason: DismissReason.userTap);
                          }
                        },
                    },
                    child: ConstrainedBox(
                      // NOTE: Using a plain ConstrainedBox (not
                      // AnimatedContainer) because the constraints only
                      // change during window resize. Running dozens of
                      // 220 ms animations concurrently during resize was
                      // the primary cause of CPU spikes and crashes.
                      constraints: Utils.horizontalConstraints(
                        context,
                        widget.queue.maxWidth,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: theme.border,
                        ),
                        child: Padding(
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
                                        style: theme
                                            .themeData.textTheme.bodyMedium
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
            );

            // Conditionally omit BackdropFilter entirely when opacity == 1.0.
            // Even `enabled: false` installs a compositing layer and can
            // schedule continuous frames in the test environment, permanently
            // blocking pumpAndSettle().
            return ClipRRect(
              borderRadius: theme.borderRadius,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                child: useBlur
                    ? BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: content,
                      )
                    : content,
              ),
            );
          },
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
      _dismissProgressController != null && !isExpanded
          ? AnimatedBuilder(
              animation: _dismissProgressController!,
              builder: (final context, final child) => Padding(
                padding: const EdgeInsetsGeometry.only(
                  right: 4,
                  left: 4,
                ),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.foregroundColor.withValues(alpha: 0.5),
                  ),
                  backgroundColor: theme.backgroundColor,
                  value: _dismissProgressController!.value,
                ),
              ),
            )
          : const SizedBox.shrink();

  Widget _getExpandButton({required final bool isExpanded}) {
    final isBottom = widget.queue.verticalDirection == VerticalDirection.up;
    final expandMoreIcon = isBottom ? Icons.expand_less : Icons.expand_more;
    final expandLessIcon = isBottom ? Icons.expand_more : Icons.expand_less;
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
          onPressed: _toggleExpanded,
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
