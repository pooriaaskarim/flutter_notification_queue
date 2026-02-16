import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_notification_queue/src/core/core.dart';
import 'package:flutter_notification_queue/src/enums/enums.dart'
    show OnLongPress;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConfigurationManager', () {
    // 1. Constructor
    test('Constructor: Can be instantiated', () {
      final manager = ConfigurationManager();
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
      final manager = ConfigurationManager();

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

      final manager = ConfigurationManager(
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
      final manager = ConfigurationManager(channels: {c1, c2});

      expect(manager.getChannel('one'), equals(c1));
      expect(manager.getChannel('two'), equals(c2));

      // Fallback
      expect(
        manager.getChannel('unknown'),
        isA<NotificationChannel>()
            .having((final c) => c.name, 'name', 'default'),
      );
    });

    // 5. Queue Resolution (Stateless)
    test('Queue Resolution: Generates queues on fly (stateless)', () {
      final manager = ConfigurationManager(); // Defaults

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

  group('Relocation Groups', () {
    // 6. Self-Inclusion
    test('Self-Inclusion: Source position is added to Relocate targets', () {
      final relocateBehavior = Relocate<OnLongPress>.to(
        {QueuePosition.centerRight, QueuePosition.centerLeft},
      );
      final manager = ConfigurationManager(
        queues: {
          TopCenterQueue(longPressDragBehavior: relocateBehavior),
        },
      );

      // After init, source position (topCenter) should be in the targets
      expect(
        relocateBehavior.positions,
        contains(QueuePosition.topCenter),
      );

      // Original targets should still be present
      expect(
        relocateBehavior.positions,
        containsAll([QueuePosition.centerRight, QueuePosition.centerLeft]),
      );

      // Should have 3 positions total
      expect(relocateBehavior.positions.length, equals(3));

      // Manager should have the source queue
      expect(manager.queues, isNotEmpty);
    });

    // 7. Group Expansion
    test('Group Expansion: Sibling queues are created for all targets', () {
      final manager = ConfigurationManager(
        queues: {
          TopCenterQueue(
            longPressDragBehavior: Relocate<OnLongPress>.to(
              {QueuePosition.centerRight, QueuePosition.centerLeft},
            ),
            style: const FilledQueueStyle(),
          ),
        },
      );

      // Should have 3 queues: topCenter + centerRight + centerLeft
      expect(manager.queues.length, equals(3));

      // Verify each sibling was created
      final centerRight = manager.getQueue(QueuePosition.centerRight);
      expect(centerRight, isA<CenterRightQueue>());

      final centerLeft = manager.getQueue(QueuePosition.centerLeft);
      expect(centerLeft, isA<CenterLeftQueue>());

      // Verify original queue remains
      final topCenter = manager.getQueue(QueuePosition.topCenter);
      expect(topCenter, isA<TopCenterQueue>());
    });

    // 8. Sibling queues inherit characteristics
    test('Group Expansion: Siblings inherit source queue characteristics', () {
      const sourceStyle = FilledQueueStyle(
        opacity: 0.5,
        elevation: 12,
      );

      final manager = ConfigurationManager(
        queues: {
          TopCenterQueue(
            longPressDragBehavior: Relocate<OnLongPress>.to(
              {QueuePosition.bottomRight},
            ),
            style: sourceStyle,
            maxStackSize: 5,
            spacing: 10.0,
          ),
        },
      );

      // Sibling should inherit style
      final sibling = manager.getQueue(QueuePosition.bottomRight);
      expect(sibling.style.runtimeType, equals(sourceStyle.runtimeType));
      expect(sibling.maxStackSize, equals(5));
      expect(sibling.spacing, equals(10.0));
    });

    // 9. Transition forwarding
    test('Group Expansion: Siblings inherit transition', () {
      const sourceTransition = ScaleTransitionStrategy();

      final manager = ConfigurationManager(
        queues: {
          TopCenterQueue(
            longPressDragBehavior: Relocate<OnLongPress>.to(
              {QueuePosition.bottomLeft},
            ),
            transition: sourceTransition,
          ),
        },
      );

      final sibling = manager.getQueue(QueuePosition.bottomLeft);
      expect(sibling.transition, isA<ScaleTransitionStrategy>());
    });

    // 10. Cross-Group Validation
    test('Cross-Group Validation: Throws on overlapping groups', () {
      expect(
        () => ConfigurationManager(
          queues: {
            TopCenterQueue(
              longPressDragBehavior: Relocate<OnLongPress>.to(
                {QueuePosition.centerRight},
              ),
            ),
            BottomCenterQueue(
              longPressDragBehavior: Relocate<OnLongPress>.to(
                {QueuePosition.centerRight}, // overlap!
              ),
            ),
          },
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    // 11. Independent groups coexist
    test('Independent Groups: Two separate groups coexist without conflict',
        () {
      final manager = ConfigurationManager(
        queues: {
          TopCenterQueue(
            longPressDragBehavior: Relocate<OnLongPress>.to(
              {QueuePosition.centerRight, QueuePosition.centerLeft},
            ),
          ),
          BottomCenterQueue(
            longPressDragBehavior: Relocate<OnLongPress>.to(
              {QueuePosition.topLeft},
            ),
          ),
        },
      );

      // Group 1: topCenter + centerRight + centerLeft = 3 queues
      // Group 2: bottomCenter + topLeft = 2 queues
      // Total: 5
      expect(manager.queues.length, equals(5));
    });

    // 12. No expansion for non-Relocate behaviors
    test('No Expansion: Dismiss/Disabled behaviors do not expand', () {
      final manager = ConfigurationManager(
        queues: {
          const TopCenterQueue(
            dragBehavior: Dismiss(),
            longPressDragBehavior: Disabled(),
          ),
        },
      );

      // Only the original queue should exist
      expect(manager.queues.length, equals(1));
    });

    // 13. Pre-configured target is not overwritten
    test('Pre-Configured Target: Existing target queue is preserved', () {
      const customStyle = FilledQueueStyle(opacity: 0.9);

      final manager = ConfigurationManager(
        queues: {
          TopCenterQueue(
            longPressDragBehavior: Relocate<OnLongPress>.to(
              {QueuePosition.topRight},
            ),
            style: const FlatQueueStyle(), // source style
          ),
          const TopRightQueue(
            style: customStyle, // explicitly configured
          ),
        },
      );

      // TopRight should keep its own explicitly configured style,
      // not inherit the source's FlatQueueStyle
      final topRight = manager.getQueue(QueuePosition.topRight);
      expect(topRight.style, equals(customStyle));
    });
  });
}
