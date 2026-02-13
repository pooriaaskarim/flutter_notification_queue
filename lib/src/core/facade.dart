part of 'core.dart';

/// The entry point for the Flutter Notification Queue package.
///
/// Use [initialize] to configure the global queues and channels.
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

  /// Access the global configuration.
  ///
  /// Throws [StateError] if [initialize] has not been called.
  static ConfigurationManager get configuration {
    if (_configuration == null) {
      throw StateError(
        'FlutterNotificationQueue is not initialized. '
        'Call FlutterNotificationQueue.initialize() before accessing '
        'configuration.',
      );
    }
    return _configuration!;
  }

  /// Access the global queue coordinator.
  ///
  /// Throws [StateError] if [initialize] has not been called.
  static QueueCoordinator get coordinator {
    if (_coordinator == null) {
      throw StateError(
        'FlutterNotificationQueue is not initialized. '
        'Call FlutterNotificationQueue.initialize() before accessing '
        'coordinator.',
      );
    }
    return _coordinator!;
  }

  /// Initialize the notification queue system with custom queues and channels.
  ///
  /// This should be called once, typically in your `main()` function.
  ///
  /// Empty/Null configuration would fallback to [NotificationQueue.defaultQueue]
  /// and [NotificationChannel.standardChannels].
  static void initialize({
    final Set<NotificationQueue>? queues,
    final Set<NotificationChannel>? channels,
  }) {
    if (isInitialized) {
      throw StateError(
        'FlutterNotificationQueue is already initialized. '
        'Do not call FlutterNotificationQueue.initialize() multiple times.',
      );
    }

    _configureLogger();
    _configuration = ConfigurationManager(
      queues: queues ?? {NotificationQueue.defaultQueue()},
      channels: channels ?? NotificationChannel.standardChannels(),
    );
    _coordinator = QueueCoordinator();
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
      handlers: [
        const Handler(
          formatter: StructuredFormatter(),
          decorators: [
            BoxDecorator(),
            HierarchyDepthPrefixDecorator(),
          ],
          sink: ConsoleSink(),
          lineLength: 120,
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
