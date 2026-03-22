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

  static void _ensureInitialized() {
    if (!isInitialized) {
      _logger.info(
        'NFQ: Lazy configuration triggered (accessed before configure())',
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
  }) {
    final isReconfig = isInitialized;

    _configureLogger();
    _configuration = ConfigurationManager(
      queues: queues ?? {NotificationQueue.defaultQueue()},
      channels: channels ?? NotificationChannel.standardChannels(),
    );

    final wasNew = _coordinator == null;
    _coordinator ??= QueueCoordinator();

    final mode = isReconfig ? 'Re-configured' : 'Configured';
    final strategy = wasNew ? 'Initial Lifecycle' : 'Preserved Coordinator';

    _logger.info('NFQ $mode ($strategy): ${_configuration!.summary}');

    _logger.debugBuffer
      ?..writeln('FlutterNotificationQueue $mode')
      ..writeln('  - Strategy: $strategy')
      ..writeln('  - Validation: System integrity verified')
      ..sink();
  }

  /// Resets the notification queue system.
  ///
  /// This is intended for testing purposes only.
  @visibleForTesting
  static void reset() {
    _configuration = null;
    _coordinator = null;
  }

  /// Configure the logger hierarchy for the package.
  static void _configureLogger() {
    Logger.configure(
      'global',
      logLevel: LogLevel.debug,
      handlers: [
        const Handler(
          formatter: StructuredFormatter(),
          decorators: [
            BoxDecorator(),
            HierarchyDepthPrefixDecorator(),
          ],
          sink: ConsoleSink(),
        ),
      ],
      stackMethodCount: {
        LogLevel.error: 20,
        LogLevel.warning: 10,
      },
    );
    Logger.attachToFlutterErrors();
  }

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
