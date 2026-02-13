import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_notification_queue/src/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConfigurationManager', () {
    // 1. Const Constructor
    test('Const Constructor: Can be instantiated as const', () {
      const manager = ConfigurationManager();
      expect(manager, isA<ConfigurationManager>());
    });

    tearDown(() {
      try {
        FlutterNotificationQueue.reset();
      } catch (_) {}
    });

    // 2. Zero-Config Initialization
    test('Zero-Config Initialization: Uses standard defaults', () {
      FlutterNotificationQueue.initialize();
      final config = FlutterNotificationQueue.configuration;

      expect(config.queues, isNotEmpty);
      expect(config.channels, isNotEmpty);

      // Verify Standard Channels
      expect(config.getChannel('success'), isNotNull);
      expect(config.getChannel('error'), isNotNull);

      // Verify Standard Queues
      // Default is desktop, which has TopRightQueue
      expect(config.getQueue(QueuePosition.topRight), isA<TopRightQueue>());
    });

    // 3. Default Configuration
    test(
        'ConfigurationManager Default Configuration: Returns'
        ' default queue and channel', () {
      const manager = ConfigurationManager();

      // Verify default queue logic (generates fallbacks)
      final queue = manager.getQueue(null);
      expect(queue, isA<TopCenterQueue>());
      expect(queue.style, isA<FilledQueueStyle>());

      // Verify default channel logic
      final channel = manager.getChannel('default');
      expect(channel.name, equals('default'));
    });

    // 3. Custom Configuration
    test('Custom Configuration: Retains provided queues and channels', () {
      const customQueue = TopRightQueue();
      const customChannel =
          NotificationChannel(name: 'custom', position: QueuePosition.topRight);

      const manager = ConfigurationManager(
        queues: {customQueue},
        channels: {customChannel},
      );

      expect(manager.getQueue(QueuePosition.topRight), equals(customQueue));
      expect(manager.getChannel('custom'), equals(customChannel));
    });

    // 4. Channel Resolution (Fallback)
    test('Channel Resolution: Falls back to first channel on miss', () {
      const c1 = NotificationChannel(name: 'one');
      const c2 = NotificationChannel(name: 'two');
      const manager = ConfigurationManager(channels: {c1, c2});

      expect(manager.getChannel('one'), equals(c1));
      expect(manager.getChannel('two'), equals(c2));

      // Fallback
      expect(manager.getChannel('unknown'), equals(c1));
    });

    // 5. Queue Resolution (Stateless)
    test('Queue Resolution: Generates queues on fly (stateless)', () {
      const manager = ConfigurationManager(); // Defaults

      // Request a position that wasn't configured
      final q1 = manager.getQueue(QueuePosition.bottomRight);
      expect(q1, isA<NotificationQueue>());
      expect(q1.position, equals(QueuePosition.bottomRight));

      // Request again - should be a new instance (no caching in immutable
      // manager) unless the system happens to return a const canonical instance
      // but getQueue uses generateQueueFrom which likely creates new.
      final q2 = manager.getQueue(QueuePosition.bottomRight);

      expect(q2.position, equals(q1.position));
      expect(q2.style.runtimeType, equals(q1.style.runtimeType));
    });
  });
}
