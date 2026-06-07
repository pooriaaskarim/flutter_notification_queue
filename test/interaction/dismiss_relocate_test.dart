import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dismiss & Relocate Interaction via onDragEnd', () {
    setUp(() {
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'test',
            position: QueuePosition.topRight,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          TopRightQueue(
            dragBehavior: Relocate.to({QueuePosition.topLeft}),
            longPressDragBehavior: const Dismiss(),
          ),
          const TopLeftQueue(), // Needed for relocation target
        },
      );
    });

    tearDown(() {
      FlutterNotificationQueue.reset();
    });

    testWidgets('Relocates to topLeft on standard drag', (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(
            body: SizedBox.expand(),
          ),
        ),
      );

      NotificationWidget(
        message: 'Drag me',
        channelName: 'test',
      ).show();
      await tester.pumpAndSettle();

      final notifFinder = find.byType(NotificationWidget);
      expect(notifFinder, findsOneWidget);

      // Get start position to calculate exact offset to (0,0)
      final startPos = tester.getCenter(notifFinder);

      // Drag exactly to topLeft (0,0)
      await tester.drag(notifFinder, Offset(-startPos.dx, -startPos.dy));
      await tester.pumpAndSettle();

      // Verify it is now in TopLeftQueue (TopRight should be unmounted)
      expect(find.byType(NotificationWidget), findsOneWidget);

      final activeQueues =
          FlutterNotificationQueue.coordinator.activeQueues.value;
      expect(activeQueues.containsKey(QueuePosition.topRight), isFalse);
      expect(activeQueues.containsKey(QueuePosition.topLeft), isTrue);
    });

    testWidgets('Dismisses to right edge on long press drag',
        (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(
            body: SizedBox.expand(),
          ),
        ),
      );

      NotificationWidget(
        message: 'Dismiss me',
        channelName: 'test',
      ).show();
      await tester.pumpAndSettle();

      final notifFinder = find.byType(NotificationWidget);
      expect(notifFinder, findsOneWidget);

      // Start long press drag
      final gesture = await tester.startGesture(tester.getCenter(notifFinder));
      // Wait for long press to activate
      await tester.pump(const Duration(milliseconds: 600));

      // Drag towards the right edge (x > 750, assuming 800x600 screen)
      await gesture.moveTo(const Offset(780, 100));
      await tester.pump();

      // Drop
      await gesture.up();
      await tester.pumpAndSettle();

      // Verify it was dismissed
      expect(find.byType(NotificationWidget), findsNothing);

      final activeQueues =
          FlutterNotificationQueue.coordinator.activeQueues.value;
      expect(activeQueues.containsKey(QueuePosition.topRight), isFalse);
    });
  });
}
