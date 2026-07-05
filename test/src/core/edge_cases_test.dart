import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_notification_queue/src/core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logd/logd.dart';
import 'package:logd/testing.dart';

void main() {
  group('FNQ Edge Cases and Reset Tests', () {
    setUp(() {
      FlutterNotificationQueue.reset();
    });

    tearDown(() {
      FlutterNotificationQueue.reset();
    });

    test('maxStackSize: 0 throws AssertionError', () {
      expect(
        () => TopCenterQueue(maxStackSize: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('Unregistered channel logs a warning and falls back to default',
        (final tester) async {
      final sink = CaptureSink();
      final handler = Handler(
        formatter: const PlainFormatter(),
        sink: sink,
      );

      FlutterNotificationQueue.configure(
        logLevel: LogLevel.warning,
        logHandlers: [handler],
        channels: {
          const NotificationChannel(
            name: 'default',
            position: QueuePosition.topCenter,
            defaultDismissDuration: null,
          ),
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: SizedBox.expand()),
        ),
      );

      final notif = NotificationWidget(
        id: 'fallback_id',
        message: 'Hello Fallback',
        channelName: 'non_existent_channel',
      );

      notif.show();
      await tester.pump();
      await tester.pump();

      // Verify the warning was logged
      expect(
        sink.logs.any((log) =>
            log.level == LogLevel.warning &&
            log.message.contains('Channel "non_existent_channel" is not registered')),
        isTrue,
      );

      // Verify the notification still renders on screen
      expect(find.text('Hello Fallback'), findsOneWidget);
    });

    testWidgets('reset() mid-display clears all queues and detaches cleanly',
        (final tester) async {
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'default',
            position: QueuePosition.topCenter,
            defaultDismissDuration: null,
          ),
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: SizedBox.expand()),
        ),
      );

      final notif = NotificationWidget(
        id: 'reset_mid_id',
        message: 'Active Notif',
      );

      notif.show();
      await tester.pump();
      await tester.pump();

      expect(find.text('Active Notif'), findsOneWidget);

      // Reset the queue system mid-display
      FlutterNotificationQueue.reset();
      await tester.pump();

      // Coordinator should be null and queues should be inactive
      expect(FlutterNotificationQueue.isInitialized, isFalse);

      // Re-configure to ensure system recovers cleanly
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'default',
            position: QueuePosition.topCenter,
            defaultDismissDuration: null,
          ),
        },
      );

      // Force widget tree to rebuild and instantiate a new NotificationOverlay
      // attached to the new coordinator.
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          builder: FlutterNotificationQueue.builder,
          home: const Scaffold(body: SizedBox.expand()),
        ),
      );

      final newNotif = NotificationWidget(
        id: 'new_id',
        message: 'New Notif',
      );
      newNotif.show();
      await tester.pump();
      await tester.pump();

      expect(find.text('New Notif'), findsOneWidget);
    });

    testWidgets('Duplicate IDs update existing active notification in-place',
        (final tester) async {
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'default',
            position: QueuePosition.topCenter,
            defaultDismissDuration: null,
          ),
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: SizedBox.expand()),
        ),
      );

      final notif1 = NotificationWidget(
        id: 'duplicate_id',
        message: 'First Message',
      );

      notif1.show();
      await tester.pump();
      await tester.pump();

      expect(find.text('First Message'), findsOneWidget);

      final notif2 = NotificationWidget(
        id: 'duplicate_id',
        message: 'Second Message',
      );

      notif2.show();
      await tester.pump();

      // The message should be updated in-place without spawning a second card
      expect(find.text('First Message'), findsNothing);
      expect(find.text('Second Message'), findsOneWidget);
    });

    testWidgets('Duplicate IDs update pending notifications in-place',
        (final tester) async {
      FlutterNotificationQueue.configure(
        queues: {
          const TopCenterQueue(
            maxStackSize: 1, // Only 1 visible at a time
          ),
        },
        channels: {
          const NotificationChannel(
            name: 'default',
            position: QueuePosition.topCenter,
            defaultDismissDuration: null,
          ),
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: SizedBox.expand()),
        ),
      );

      final first = NotificationWidget(
        id: 'visible_id',
        message: 'Visible',
      );
      first.show();
      await tester.pump();
      await tester.pump();

      final pending1 = NotificationWidget(
        id: 'pending_id',
        message: 'Pending 1',
      );
      pending1.show();
      await tester.pump();

      final pending2 = NotificationWidget(
        id: 'pending_id',
        message: 'Pending 2',
      );
      pending2.show();
      await tester.pump();

      // Now trigger dismiss of the visible one.
      // Do not await the future directly as it blocks the FakeAsync zone until pumped.
      final Future<void> dismissFuture = first.dismiss();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await dismissFuture;

      // Pump exit size transition (200ms) and entry size/slide transitions (300ms)
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // The pending notification should show "Pending 2" because it was updated in-place
      expect(find.text('Pending 1'), findsNothing);
      expect(find.text('Pending 2'), findsOneWidget);
    });
  });
}

