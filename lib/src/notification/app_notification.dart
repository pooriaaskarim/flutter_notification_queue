part of 'notification.dart';

/// Represents an in-app notification payload to be enqueued and displayed.
///
/// [AppNotification] is a pure, immutable data object that encapsulates the
/// content (title, message, icon), visual overrides (colors), interaction
/// behaviors (tap, drag, long-press), and routing metadata (channel, priority,
/// position) for a single notification.
///
/// Unlike UI widgets, [AppNotification] has no UI dependencies, requires no
/// [BuildContext], and performs no direct side effects. It represents the
/// *intent* to show a notification. Pass instances to a
/// `NotificationController` or dispatch them via
/// `NotificationScope.of(context)`.
///
/// ## Basic Usage
///
/// ```dart
/// final notification = AppNotification(
///   id: 'order-123',
///   message: 'Your order #123 has been confirmed.',
///   title: 'Order Confirmed',
///   channelName: 'orders',
///   priority: NotificationPriority.high,
///   dismissDuration: const Duration(seconds: 5),
/// );
///
/// // Dispatch via controller or context
/// controller.show(notification);
/// ```
///
/// See also:
///  * [NotificationChannel], which defines channel-level defaults for
///    notifications.
///  * [NotificationPriority], which determines triage ranking in the queue.
///  * [TapBehavior] and [DragBehavior], which define gesture interactions.
@immutable
class AppNotification {
  /// Creates an immutable [AppNotification] payload.
  ///
  /// The [message] parameter is required and represents the main text body.
  ///
  /// Use [channelName] to route the notification through a specific registered
  /// [NotificationChannel] (defaults to `'default'`).
  ///
  /// Override visual style settings like [color], [backgroundColor], and
  /// [foregroundColor] to customize the card's appearance.
  ///
  /// Set [permanent] to `true` to keep the notification on screen until
  /// explicitly dismissed by the user or programmatically.
  const AppNotification({
    required this.message,
    this.id,
    this.title,
    this.channelName = 'default',
    this.position,
    this.priority,
    this.tapBehavior,
    this.dragBehavior,
    this.longPressDragBehavior,
    this.groupKey,
    this.icon,
    this.color,
    this.foregroundColor,
    this.backgroundColor,
    this.dismissDuration,
    this.permanent = false,
    this.initialIsPinned = false,
    this.snoozedAt,
    this.builder,
    this.action,
  });

  /// The main message text body of the notification.
  final String message;

  /// Optional unique identifier for this notification.
  ///
  /// If `null`, a unique ID is automatically generated when enqueued.
  final String? id;

  /// Optional header title text shown above the [message].
  final String? title;

  /// Name of the target [NotificationChannel] for default settings and routing.
  ///
  /// Defaults to `'default'`. If the specified channel is not registered,
  /// fallbacks from the global default channel are applied.
  final String channelName;

  /// Optional override for the target screen position of the queue.
  ///
  /// When `null`, the position is resolved from the channel's configured
  /// position or the default queue position.
  final QueuePosition? position;

  /// Optional priority rank override for queue triage and backpressure.
  ///
  /// When `null`, defaults to the priority defined on the
  /// [NotificationChannel].
  final NotificationPriority? priority;

  //todo: RationaliZe having tap, drag, longPressDragBehavior overrides 
  //todo: inside notification, since they are inherently Queue properties.
  /// Per-notification override for tap interaction behavior.
  ///
  /// When set, this takes precedence over the queue's default [TapBehavior].
  final TapBehavior? tapBehavior;

  /// Per-notification override for drag interaction behavior.
  ///
  /// When set, this takes precedence over the queue's default [DragBehavior].
  final DragBehavior? dragBehavior;

  /// Per-notification override for long-press drag interaction behavior.
  final LongPressDragBehavior? longPressDragBehavior;

  /// Optional grouping key for bundling notifications into stack pills.
  ///
  /// Notifications sharing the same [groupKey] will be collapsed together.
  /// If `null`, grouping falls back to [channelName].
  final String? groupKey;

  /// Leading icon widget displayed beside the [message].
  ///
  /// If `null`, falls back to the icon defined on the target
  /// [NotificationChannel].
  final Widget? icon;

  /// Main accent color used for icons, borders, and body highlights.
  ///
  /// If `null`, falls back to the channel's default color or theme primary.
  final Color? color;

  /// Foreground text, action button, and progress indicator color.
  ///
  /// If `null`, falls back to the channel's default foreground color or theme
  /// `onSurface`.
  final Color? foregroundColor;

  /// Card body background color.
  ///
  /// If `null`, falls back to the channel's default background color or theme
  /// `surface`.
  final Color? backgroundColor;

  /// Auto-dismiss timer duration for this notification.
  ///
  /// When `null` and [permanent] is `false`, the notification uses the default
  /// dismiss duration from its [NotificationChannel].
  final Duration? dismissDuration;

  /// Whether the notification stays on screen indefinitely until dismissed.
  ///
  /// Setting [permanent] to `true` overrides any [dismissDuration] settings.
  final bool permanent;

  /// Whether the notification starts in a pinned state upon initial display.
  ///
  /// Pinned notifications are immune to auto-dismiss timers and swipe dismiss.
  final bool initialIsPinned;

  /// Optional timestamp recording when this notification was snoozed.
  final DateTime? snoozedAt;

  /// Custom builder for customizing the card indicator or stack appearance.
  final NotificationBuilder? builder;

  /// Action button or tap callback configuration attached to the card.
  final NotificationAction? action;

  /// Internal conversion helper to adapt [AppNotification] to
  /// [NotificationWidget] for rendering pipeline compatibility during v0.3.0.
  @internal
  NotificationWidget toWidget([
    final ConfigurationManager? configuration,
    final QueueCoordinator? coordinator,
  ]) =>
      NotificationWidget(
        message: message,
        id: id,
        channelName: channelName,
        title: title,
        position: position,
        action: action,
        tapBehavior: tapBehavior,
        dragBehavior: dragBehavior,
        longPressDragBehavior: longPressDragBehavior,
        icon: icon,
        color: color,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        dismissDuration: dismissDuration,
        permanent: permanent,
        builder: builder,
        priority: priority,
        initialIsPinned: initialIsPinned,
        snoozedAt: snoozedAt,
        groupKey: groupKey,
        configuration: configuration,
        coordinator: coordinator,
      );

  /// Creates a copy of this [AppNotification] with the given fields replaced.
  AppNotification copyWith({
    final String? id,
    final String? title,
    final String? message,
    final String? channelName,
    final QueuePosition? position,
    final NotificationPriority? priority,
    final TapBehavior? tapBehavior,
    final DragBehavior? dragBehavior,
    final LongPressDragBehavior? longPressDragBehavior,
    final String? groupKey,
    final Widget? icon,
    final Color? color,
    final Color? foregroundColor,
    final Color? backgroundColor,
    final Duration? dismissDuration,
    final bool? permanent,
    final bool? initialIsPinned,
    final DateTime? snoozedAt,
    final NotificationBuilder? builder,
    final NotificationAction? action,
  }) =>
      AppNotification(
        id: id ?? this.id,
        title: title ?? this.title,
        message: message ?? this.message,
        channelName: channelName ?? this.channelName,
        position: position ?? this.position,
        priority: priority ?? this.priority,
        tapBehavior: tapBehavior ?? this.tapBehavior,
        dragBehavior: dragBehavior ?? this.dragBehavior,
        longPressDragBehavior:
            longPressDragBehavior ?? this.longPressDragBehavior,
        groupKey: groupKey ?? this.groupKey,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        foregroundColor: foregroundColor ?? this.foregroundColor,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        dismissDuration: dismissDuration ?? this.dismissDuration,
        permanent: permanent ?? this.permanent,
        initialIsPinned: initialIsPinned ?? this.initialIsPinned,
        snoozedAt: snoozedAt ?? this.snoozedAt,
        builder: builder ?? this.builder,
        action: action ?? this.action,
      );

  /// Internal conversion helper to create a [NotificationEntry] from this
  /// intent.
  @internal
  NotificationEntry toEntry() {
    final widget = toWidget();
    return NotificationEntry(
      blueprint: widget,
      queue: widget.queue,
    );
  }

  @override
  String toString() => 'AppNotification('
      'id: $id, '
      'channelName: $channelName, '
      'title: $title, '
      'message: $message, '
      'priority: $priority, '
      'groupKey: $groupKey)';
}
