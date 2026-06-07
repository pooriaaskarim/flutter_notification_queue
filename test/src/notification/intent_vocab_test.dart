import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_notification_queue/src/enums/enums.dart';
import 'package:flutter_test/flutter_test.dart';

// Bounded pump sequence that drives the 300ms entry/exit animation to
// completion without ever calling pumpAndSettle() (which hangs when any
// AnimationController or broadcast subscription is still active).
Future<void> _driveAnimation(final WidgetTester tester) async {
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('Intent-First Interaction Vocabulary unit tests', () {
    test('Snooze and CustomAction behavior properties are correct', () {
      const snooze = Snooze<OnDrag>(duration: Duration(seconds: 5));
      expect(snooze.duration, const Duration(seconds: 5));

      const custom = CustomAction<OnDrag>(actionName: 'custom_test');
      expect(custom.actionName, 'custom_test');
    });

    test('NotificationWidget handles isPinned and snoozedAt correctly', () {
      final now = DateTime.now();
      final n = NotificationWidget(
        message: 'Intent test',
        initialIsPinned: true,
        snoozedAt: now,
      );

      expect(n.isPinned, isTrue);
      expect(n.snoozedAt, now);

      n.isPinned = false;
      expect(n.isPinned, isFalse);
    });

    test('copyToQueue preserves isPinned and snoozedAt', () {
      final now = DateTime.now();
      final n = NotificationWidget(
        message: 'Copy test',
        initialIsPinned: true,
        snoozedAt: now,
      );

      final copy = n.copyToQueue(const TopRightQueue());
      expect(copy.isPinned, isTrue);
      expect(copy.snoozedAt, now);
    });

    tearDown(() {
      FlutterNotificationQueue.reset();
    });
  });

  group('Intent-First Coordinator and Event integration tests', () {
    setUp(() {
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'test',
            position: QueuePosition.topRight,
            defaultDismissDuration: null,
          ),
          // Must also configure 'default' channel with null duration to prevent
          // the fallback channel from scheduling a background dismiss timer.
          const NotificationChannel(
            name: 'default',
            position: QueuePosition.topRight,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const TopRightQueue(),
        },
      );
    });

    tearDown(() {
      FlutterNotificationQueue.reset();
    });

    testWidgets('pin and unpin programmatically toggle state and emit events',
        (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: SizedBox.expand()),
        ),
      );

      final n = NotificationWidget(
        id: 'pin_test_id',
        message: 'To be pinned',
        channelName: 'test',
      );

      final List<FnqEvent> capturedEvents = [];
      final sub = FlutterNotificationQueue.events.listen(capturedEvents.add);

      n.show();
      await tester.pump(); // Build layout frame
      await tester.pump(); // Flush post-frame registrations

      // Drive the 300ms entry animation to completion.
      await _driveAnimation(tester);

      FlutterNotificationQueue.coordinator.pin(n);
      await tester.pump();
      await tester.pump();

      FlutterNotificationQueue.coordinator.unpin(n);
      await tester.pump();
      await tester.pump();

      // IMPORTANT: Use synchronous cancel (no await) in FakeAsync zones.
      // await sub.cancel() would deadlock because the future cannot resolve
      // until the event loop advances, but the event loop is suspended.
      sub.cancel(); // ignore: unawaited_futures

      // Drive any remaining style transitions to completion.
      await _driveAnimation(tester);

      final stateKey = GlobalObjectKey<NotificationWidgetState>(n.id);
      expect(stateKey.currentState?.widget.isPinned, isFalse);
      expect(
        capturedEvents.any(
          (final e) => e is NotificationPinned && e.notification.id == n.id,
        ),
        isTrue,
      );
      expect(
        capturedEvents.any(
          (final e) => e is NotificationUnpinned && e.notification.id == n.id,
        ),
        isTrue,
      );
    });

    testWidgets('custom action triggering emits the correct event',
        (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: SizedBox.expand()),
        ),
      );

      final n = NotificationWidget(
        id: 'action_test_id',
        message: 'Custom action target',
        channelName: 'test',
      );

      final List<FnqEvent> capturedEvents = [];
      final sub = FlutterNotificationQueue.events.listen(capturedEvents.add);

      n.show();
      await tester.pump();
      await tester.pump();
      await _driveAnimation(tester);

      FlutterNotificationQueue.coordinator.triggerCustomAction(n, 'archive');
      await tester.pump();
      await tester.pump();

      sub.cancel(); // ignore: unawaited_futures
      await _driveAnimation(tester);

      final customEvent = capturedEvents.firstWhere(
        (final e) => e is NotificationCustomActionTriggered,
      ) as NotificationCustomActionTriggered;

      expect(customEvent.notification.id, n.id);
      expect(customEvent.actionName, 'archive');
    });

    testWidgets('snooze programmatically dismisses and schedules re-enqueuing',
        (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: SizedBox.expand()),
        ),
      );

      final n = NotificationWidget(
        id: 'snooze_test_id',
        message: 'Snoozed notification',
        channelName: 'test',
      );

      final List<FnqEvent> capturedEvents = [];
      final sub = FlutterNotificationQueue.events.listen(capturedEvents.add);

      n.show();
      await tester.pump();
      await tester.pump();
      await _driveAnimation(tester);

      expect(find.text('Snoozed notification'), findsOneWidget);

      // Snooze for 500ms — longer than any transition.
      FlutterNotificationQueue.coordinator.snooze(
        n,
        const Duration(milliseconds: 500),
      );

      // Flush the stream microtask so the NotificationSnoozed event is
      // delivered to the listener before we cancel the subscription.
      // Broadcast stream events are dispatched asynchronously — cancel()
      // before the microtask runs will swallow the event.
      await tester.pump();

      // Now cancel synchronously. The event is already in capturedEvents.
      sub.cancel(); // ignore: unawaited_futures

      // pumpAndSettle is now safe: no open subscription, no background timer
      // (defaultDismissDuration: null). This settles the immediate removal.
      await tester.pumpAndSettle();

      expect(find.text('Snoozed notification'), findsNothing);
      expect(
        capturedEvents.any(
          (final e) => e is NotificationSnoozed && e.notification.id == n.id,
        ),
        isTrue,
      );

      // Step the clock past the 500ms snooze timer to trigger re-enqueue.
      await tester.pump(const Duration(milliseconds: 550));

      // Drive the re-entry animation (300ms) to completion.
      await _driveAnimation(tester);

      expect(find.text('Snoozed notification'), findsOneWidget);
    });
  });
}
