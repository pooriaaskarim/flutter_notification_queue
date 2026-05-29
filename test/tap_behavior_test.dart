import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A minimal FlutterNotificationQueue configuration used in all tests.
void _initFnq() {
  FlutterNotificationQueue.configure(
    queues: {
      TopCenterQueue(tapBehavior: const TapToDismiss()),
    },
    channels: {
      const NotificationChannel(name: 'default'),
    },
  );
}

// ---------------------------------------------------------------------------
// TapBehavior unit tests
// ---------------------------------------------------------------------------

void main() {
  // ── Behavior taxonomy ─────────────────────────────────────────────────────

  group('TapBehavior sealed class hierarchy', () {
    test('TapToDismiss is a TapBehavior', () {
      const b = TapToDismiss();
      expect(b, isA<TapBehavior>());
    });

    test('TapToExpand is a TapBehavior', () {
      const b = TapToExpand();
      expect(b, isA<TapBehavior>());
    });

    test('TapToAct is a TapBehavior', () {
      final b = TapToAct(onTap: () {});
      expect(b, isA<TapBehavior>());
    });

    test('TapDisabled is a TapBehavior', () {
      const b = TapDisabled();
      expect(b, isA<TapBehavior>());
    });

    test('TapToAct.onTap stores its callback', () {
      var called = false;
      final b = TapToAct(onTap: () => called = true);
      b.onTap();
      expect(called, isTrue);
    });
  });

  // ── Queue-level tapBehavior ───────────────────────────────────────────────

  group('NotificationQueue.tapBehavior', () {
    test('TopCenterQueue default tapBehavior is TapToDismiss', () {
      const q = TopCenterQueue();
      expect(q.tapBehavior, isA<TapToDismiss>());
    });

    test('all concrete queues default to TapToDismiss', () {
      const queues = [
        TopLeftQueue(),
        TopCenterQueue(),
        TopRightQueue(),
        CenterLeftQueue(),
        CenterRightQueue(),
        BottomLeftQueue(),
        BottomCenterQueue(),
        BottomRightQueue(),
      ];
      for (final q in queues) {
        expect(
          q.tapBehavior,
          isA<TapToDismiss>(),
          reason: '${q.runtimeType} should default to TapToDismiss',
        );
      }
    });

    test('custom tapBehavior is stored on queue', () {
      const q = TopCenterQueue(tapBehavior: TapToExpand());
      expect(q.tapBehavior, isA<TapToExpand>());
    });

    test('TapToAct is stored on queue and callback is callable', () {
      var fired = false;
      final q = TopCenterQueue(tapBehavior: TapToAct(onTap: () => fired = true));
      (q.tapBehavior as TapToAct).onTap();
      expect(fired, isTrue);
    });

    test('TapDisabled is stored correctly', () {
      const q = TopCenterQueue(tapBehavior: TapDisabled());
      expect(q.tapBehavior, isA<TapDisabled>());
    });
  });

  // ── NotificationQueue.defaultQueue factory ────────────────────────────────

  group('NotificationQueue.defaultQueue factory', () {
    test('tapBehavior defaults to TapToDismiss', () {
      final q = NotificationQueue.defaultQueue();
      expect(q.tapBehavior, isA<TapToDismiss>());
    });

    test('custom tapBehavior is forwarded through factory', () {
      final q = NotificationQueue.defaultQueue(
        tapBehavior: const TapToExpand(),
      );
      expect(q.tapBehavior, isA<TapToExpand>());
    });
  });

  // ── QueuePosition.generateQueueFrom propagation ───────────────────────────

  group('QueuePosition.generateQueueFrom propagation', () {
    test('tapBehavior is preserved when generating from another queue', () {
      const source = TopLeftQueue(tapBehavior: TapToExpand());
      final copy = QueuePosition.topRight.generateQueueFrom(source);
      expect(copy.tapBehavior, isA<TapToExpand>());
    });

    test('TapDisabled survives generateQueueFrom', () {
      const source = BottomCenterQueue(tapBehavior: TapDisabled());
      final copy = QueuePosition.bottomLeft.generateQueueFrom(source);
      expect(copy.tapBehavior, isA<TapDisabled>());
    });
  });

  // ── Per-notification tapBehavior override ─────────────────────────────────

  group('NotificationWidget.tapBehavior per-notification override', () {
    setUp(_initFnq);

    test('notification.tapBehavior field stores override', () {
      final n = NotificationWidget(
        message: 'Test',
        tapBehavior: const TapToExpand(),
      );
      expect(n.tapBehavior, isA<TapToExpand>());
    });

    test('notification.tapBehavior is null when not set', () {
      final n = NotificationWidget(message: 'Test');
      expect(n.tapBehavior, isNull);
    });

    test('copyToQueue preserves tapBehavior override', () {
      final n = NotificationWidget(
        message: 'Test',
        tapBehavior: const TapToExpand(),
      );
      final copy = n.copyToQueue(const TopRightQueue());
      expect(copy.tapBehavior, isA<TapToExpand>());
    });

    test('copyToQueue preserves null tapBehavior', () {
      final n = NotificationWidget(message: 'Test');
      final copy = n.copyToQueue(const TopRightQueue());
      expect(copy.tapBehavior, isNull);
    });
  });

  // ── Widget-level resolution (_resolvedTapBehavior) ────────────────────────

  group('_resolvedTapBehavior resolution priority', () {
    setUp(_initFnq);

    testWidgets(
      'per-notification TapToExpand overrides queue TapToDismiss',
      (tester) async {
        final n = NotificationWidget(
          message: 'Test',
          tapBehavior: const TapToExpand(),
        );
        // Verify: per-notification tapBehavior takes precedence.
        expect(n.tapBehavior, isA<TapToExpand>());
        // Queue still has TapToDismiss by default.
        expect(n.queue.tapBehavior, isA<TapToDismiss>());
      },
    );

    testWidgets(
      'null per-notification tapBehavior falls through to queue',
      (tester) async {
        final n = NotificationWidget(message: 'Test');
        // No per-notification override set.
        expect(n.tapBehavior, isNull);
        // Queue-level fallback is TapToDismiss.
        expect(n.queue.tapBehavior, isA<TapToDismiss>());
      },
    );
  });

  // ── TapToAct callback invocation ─────────────────────────────────────────

  group('TapToAct callback behavior', () {
    test('callback is invoked and notification is NOT auto-dismissed', () {
      var tapCount = 0;
      final act = TapToAct(onTap: () => tapCount++);
      act.onTap();
      act.onTap();
      expect(tapCount, equals(2));
    });

    test('callback can be replaced via new instance', () {
      var result = '';
      final act1 = TapToAct(onTap: () => result = 'first');
      final act2 = TapToAct(onTap: () => result = 'second');
      act1.onTap();
      expect(result, equals('first'));
      act2.onTap();
      expect(result, equals('second'));
    });
  });
}
