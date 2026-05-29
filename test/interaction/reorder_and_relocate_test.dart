import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReorderAndRelocate Interaction via onDragEnd', () {
    setUp(() {
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'test',
            position: QueuePosition.topRight,
          ),
        },
        queues: {
          TopRightQueue(
            dragBehavior: ReorderAndRelocate.to(
              positions: {QueuePosition.topLeft},
              escapeThresholdInPixels: 50.0,
            ),
          ),
          const TopLeftQueue(), // Destination queue
        },
      );
    });

    tearDown(() {
      FlutterNotificationQueue.reset();
    });

    testWidgets('Drag within queue triggers reorder', (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(
            body: SizedBox.expand(),
          ),
        ),
      );

      final notification1 = NotificationWidget(
        message: 'Item 1',
        channelName: 'test',
      );

      final notification2 = NotificationWidget(
        message: 'Item 2',
        channelName: 'test',
      );

      notification1.show();
      await tester.pumpAndSettle();

      notification2.show();
      await tester.pumpAndSettle();

      final notifFinder1 = find.text('Item 1');
      final notifFinder2 = find.text('Item 2');
      expect(notifFinder1, findsOneWidget);
      expect(notifFinder2, findsOneWidget);

      final startPos = tester.getCenter(notifFinder2);
      final targetPos = tester.getCenter(notifFinder1);

      final gesture = await tester.startGesture(startPos);
      await tester.pump(const Duration(milliseconds: 100));

      // Move slightly to stay within queue boundary
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.moveTo(targetPos);
      await tester.pump();

      await gesture.up();
      await tester.pumpAndSettle();

      final newPos1 = tester.getCenter(notifFinder1);
      final newPos2 = tester.getCenter(notifFinder2);

      // Item 2 should now be visually at Item 1's old position
      expect(newPos2.dy, closeTo(targetPos.dy, 1.0));
      // Item 1 should be shifted down
      expect(newPos1.dy, closeTo(startPos.dy, 1.0));
    });

    testWidgets('Drag out of queue triggers relocate', (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(
            body: SizedBox.expand(),
          ),
        ),
      );

      NotificationWidget(
        message: 'Item 1',
        channelName: 'test',
      ).show();
      await tester.pumpAndSettle();

      final notifFinder1 = find.text('Item 1');
      expect(notifFinder1, findsOneWidget);

      final startPos = tester.getCenter(notifFinder1);

      final gesture = await tester.startGesture(startPos);
      await tester.pump(const Duration(milliseconds: 100));

      // Move slightly to break the drag slop and initiate the drag
      await gesture.moveBy(const Offset(-20, -20));
      await tester.pump();

      // Move out of queue boundary to the top-left to trigger Relocate to
      // topLeft.
      await gesture.moveTo(const Offset(20, 20)); // Top left corner
      await tester.pump();

      await gesture.up();
      await tester.pumpAndSettle();

      // Check if it's now in the top left queue by verifying its position
      final newPos1 = tester.getCenter(notifFinder1);
      expect(newPos1.dx, lessThan(400)); // It should be on the left side
      expect(newPos1.dy, lessThan(400)); // It should be on the top side
    });

    testWidgets(
        'ReorderAndRelocate configures self-inclusion of master queue '
        'as relocatable target', (final tester) async {
      final queue = FlutterNotificationQueue.configuration
          .getQueue(QueuePosition.topRight);
      final behavior = queue.dragBehavior as ReorderAndRelocate;

      // The original positions Set did not include topRight (the master queue),
      // but ConfigurationManager must dynamically expand it to include the
      // source to permit dragging back home.
      expect(behavior.positions, contains(QueuePosition.topRight));
      expect(behavior.positions, contains(QueuePosition.topLeft));
    });
  });
}
