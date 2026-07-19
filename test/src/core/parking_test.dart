import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _driveAnimation(final WidgetTester tester) async {
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('F-03 Desktop Parking & Runtime Config Tests', () {
    setUp(() {
      FlutterNotificationQueue.reset();
    });

    tearDown(() {
      FlutterNotificationQueue.reset();
    });

    testWidgets(
        'dynamic channel parking: disabled by default and does not change '
        'routes', (final tester) async {
      FlutterNotificationQueue.configure(
        enableDynamicChannelParking: false,
        channels: {
          const NotificationChannel(
            name: 'test_info',
            position: QueuePosition.topRight,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          NotificationQueue(
            position: QueuePosition.topRight,
            longPressDragBehavior: Relocate.to({QueuePosition.topLeft}),
          ),
          const NotificationQueue(
            position: QueuePosition.topLeft,
          ),
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: SizedBox.expand()),
        ),
      );

      final n1 = NotificationWidget(
        id: 'notif_1',
        message: 'Message 1',
        channelName: 'test_info',
      )..show();
      await tester.pump();
      await tester.pump();
      await _driveAnimation(tester);

      expect(find.text('Message 1'), findsOneWidget);

      // Relocate n1 to topLeft
      FlutterNotificationQueue.coordinator.relocate(n1, QueuePosition.topLeft);
      await tester.pump();
      await tester.pumpAndSettle();

      // Fire a second notification of the same channel
      final n2 = NotificationWidget(
        id: 'notif_2',
        message: 'Message 2',
        channelName: 'test_info',
      )..show();
      await tester.pump();
      await tester.pump();
      await _driveAnimation(tester);

      // Verify that n2 is still routed to the original position (topRight),
      // not topLeft
      final stateKey = GlobalObjectKey<NotificationWidgetState>(n2.id);
      expect(
        stateKey.currentState?.widget.queue.position,
        equals(QueuePosition.topRight),
      );
    });

    testWidgets('dynamic channel parking: enabled updates routes dynamically',
        (final tester) async {
      FlutterNotificationQueue.configure(
        enableDynamicChannelParking: true,
        channels: {
          const NotificationChannel(
            name: 'test_info',
            position: QueuePosition.topRight,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          NotificationQueue(
            position: QueuePosition.topRight,
            longPressDragBehavior: Relocate.to({QueuePosition.topLeft}),
          ),
          const NotificationQueue(
            position: QueuePosition.topLeft,
          ),
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(body: SizedBox.expand()),
        ),
      );

      final n1 = NotificationWidget(
        id: 'notif_1',
        message: 'Message 1',
        channelName: 'test_info',
      )..show();

      final List<FnqEvent> capturedEvents = [];
      final sub = FlutterNotificationQueue.events.listen(capturedEvents.add);
      await tester.pump();
      await tester.pump();
      await _driveAnimation(tester);

      expect(find.text('Message 1'), findsOneWidget);

      // Relocate n1 to topLeft
      FlutterNotificationQueue.coordinator.relocate(n1, QueuePosition.topLeft);
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify dynamic route update event was fired
      expect(
        capturedEvents.any(
          (final e) =>
              e is NotificationChannelRouteUpdated &&
              e.channelName == 'test_info' &&
              e.oldPosition == QueuePosition.topRight &&
              e.newPosition == QueuePosition.topLeft,
        ),
        isTrue,
      );

      // Fire a second notification of the same channel
      final n2 = NotificationWidget(
        id: 'notif_2',
        message: 'Message 2',
        channelName: 'test_info',
      )..show();
      await tester.pump();
      await tester.pump();
      await _driveAnimation(tester);

      sub.cancel(); // ignore: unawaited_futures

      // Verify that n2 is now routed to topLeft!
      final stateKey = GlobalObjectKey<NotificationWidgetState>(n2.id);
      expect(
        stateKey.currentState?.widget.queue.position,
        equals(QueuePosition.topLeft),
      );
    });
  });
}
