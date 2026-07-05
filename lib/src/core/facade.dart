part of 'core.dart';

/// The entry point for the Flutter Notification Queue package.
///
/// Use [configure] to configure the global queues and channels.
///
/// Use [builder] in [MaterialApp.builder] to integrate contextless
///  notification support into your app.
final class FlutterNotificationQueue {
  const FlutterNotificationQueue._();

  /// Whether the notification queue system has been initialized.
  static bool get isInitialized =>
      _configuration != null && _coordinator != null;

  static ConfigurationManager? _configuration;
  static QueueCoordinator? _coordinator;
  static bool _isFlutterErrorHooked = false;

  // Stable broadcast proxy that re-routes to the current coordinator's stream.
  // Listeners attached before a reset()+configure() cycle continue to receive
  // events from the new coordinator without needing to re-subscribe.
  // Using sync: true ensures that event propagation has zero microtask delay
  // when forwarding from the coordinator's stream, preserving test
  // compatibility.
  static final _proxyController =
      StreamController<FnqEvent>.broadcast(sync: true);
  static StreamSubscription<FnqEvent>? _coordinatorEventSub;

  static final _logger = Logger.get('fnq.Core');

  /// Access the global configuration.
  ///
  /// Automatically calls [configure] with defaults if not already initialized.
  static ConfigurationManager get configuration {
    _ensureInitialized();
    return _configuration!;
  }

  /// Access the global queue coordinator.
  ///
  /// Automatically calls [configure] with defaults if not already initialized.
  static QueueCoordinator get coordinator {
    _ensureInitialized();
    return _coordinator!;
  }

  /// A broadcast stream of all notification lifecycle events.
  ///
  /// This stream is **stable across `configure()` calls**. Listeners attached
  /// once survive `reset()` + `configure()` cycles without re-subscribing.
  ///
  /// Example:
  /// ```dart
  /// FlutterNotificationQueue.events.listen((event) {
  ///   switch (event) {
  ///     case NotificationQueued(:final notification):
  ///       analytics.track('shown', id: notification.id);
  ///     case NotificationDismissed(:final reason):
  ///       if (reason == DismissReason.timeout) log('auto-dismissed');
  ///     case NotificationTapped(:final behavior):
  ///       log('tapped with ${behavior.runtimeType}');
  ///     case NotificationRelocated(:final from, :final to):
  ///     case NotificationReordered(:final toIndex):
  ///     case QueueOverflowed():
  ///   }
  /// });
  /// ```
  static Stream<FnqEvent> get events => _proxyController.stream;

  static void _ensureInitialized() {
    if (!isInitialized) {
      _logger.warning(
        'FNQ: configure() was not called before first use. '
        'Applying defaults (topCenter queue + standard channels). '
        'Call FlutterNotificationQueue.configure() in main() to customise.',
      );
      configure();
    }
  }

  /// Configure the notification queue system with custom queues and channels.
  ///
  /// This should be called to set up the system, typically in your `main()`
  /// function, but can be called again to reconfigure at runtime.
  ///
  /// Empty/Null configuration would fallback to [NotificationQueue.defaultQueue]
  /// and [NotificationChannel.standardChannels].
  static void configure({
    final Set<NotificationQueue>? queues,
    final Set<NotificationChannel>? channels,
    final LogLevel? logLevel,
    final List<Handler>? logHandlers,
    final bool captureFlutterErrors = false,
    final bool strictChannelLookup = false,
  }) {
    final isReconfig = isInitialized;

    _configureLogger(
      customLevel: logLevel,
      customHandlers: logHandlers,
      captureFlutterErrors: captureFlutterErrors,
    );
    _configuration = ConfigurationManager(
      queues: queues ?? {NotificationQueue.defaultQueue()},
      channels: channels ?? NotificationChannel.standardChannels(),
      strictChannelLookup: strictChannelLookup,
    );

    final wasNew = _coordinator == null;
    _coordinator ??= QueueCoordinator();

    // Re-wire the proxy stream to the (potentially new) coordinator.
    _coordinatorEventSub?.cancel();
    _coordinatorEventSub = _coordinator!.events.listen(_proxyController.add);

    final mode = isReconfig ? 'Re-configured' : 'Configured';
    final strategy = wasNew ? 'Initial Lifecycle' : 'Preserved Coordinator';

    _logger.info('NFQ $mode ($strategy): ${_configuration!.summary}');

    _logger.debugBuffer
      ?..writeln('FlutterNotificationQueue $mode')
      ..writeln('  - Strategy: $strategy')
      ..writeln('  - Validation: System integrity verified')
      ..sink();
  }

  @visibleForTesting
  static void reset() {
    _coordinatorEventSub?.cancel();
    _coordinatorEventSub = null;
    _coordinator?.detach();
    _configuration = null;
    _coordinator = null;
    // Reset input-device detection so tests that fire hover events do not
    // affect subsequent tests that run in the same process.
    VisibleOnHover.resetMouseDetection();
  }

  /// Configure the logger hierarchy for the package.
  static void _configureLogger({
    final LogLevel? customLevel,
    final List<Handler>? customHandlers,
    final bool captureFlutterErrors = false,
  }) {
    const bool isDebug = kDebugMode;
    final LogLevel resolvedLevel =
        customLevel ?? (isDebug ? LogLevel.debug : LogLevel.warning);

    final List<Handler> resolvedHandlers = customHandlers ??
        (isDebug
            ? [
                const Handler(
                  formatter: StructuredFormatter(),
                  decorators: [
                    BoxDecorator(),
                    HierarchyDepthPrefixDecorator(),
                  ],
                  sink: ConsoleSink(),
                ),
              ]
            : const []);

    Logger.configure(
      'fnq',
      logLevel: resolvedLevel,
      handlers: resolvedHandlers,
      stackMethodCount: {
        LogLevel.error: 20,
        LogLevel.warning: 10,
      },
    );

    if (captureFlutterErrors && !_isFlutterErrorHooked) {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (final details) {
        Logger.get('fnq.flutter.error').error(
          details.exceptionAsString(),
          stackTrace: details.stack,
        );
        originalOnError?.call(details);
      };
      _isFlutterErrorHooked = true;
    }
  }

  /// Quickly displays a new notification with the given properties.
  ///
  /// This is a convenience static wrapper around [NotificationWidget.show].
  static void show({
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
  }) {
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
    ).show();
  }

  /// A test helper that returns a [Future] that completes with the first
  /// [FnqEvent] of type [T].
  @visibleForTesting
  static Future<T> nextEvent<T extends FnqEvent>() =>
      events.where((final e) => e is T).cast<T>().first;

  /// Static builder method for use in [MaterialApp.builder].
  ///
  /// This integrates contextless notification support into your app.
  ///
  /// Usage:
  /// ```dart
  /// MaterialApp(
  ///   builder: FlutterNotificationQueue.builder,
  /// );
  /// ```
  static Widget builder(final BuildContext context, final Widget? child) =>
      NotificationOverlay.router(context, child);
}
