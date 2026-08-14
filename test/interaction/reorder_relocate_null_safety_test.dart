import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Reorder & Relocate Null Safety', () {
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
          NotificationQueue(
            position: QueuePosition.topRight,
            dragBehavior: ReorderAndRelocate.to(
              positions: {
                QueuePosition.topRight,
                QueuePosition.topLeft,
              },
            ),
          ),
          const NotificationQueue(
            position: QueuePosition.topLeft,
          ),
        },
      );
    });

    tearDown(() {
      FlutterNotificationQueue.reset();
    });

    testWidgets(
      'Reorder dragging feedback builds cleanly without null coordinator '
      'errors',
      (final tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            builder: FlutterNotificationQueue.builder,
            home: Scaffold(
              body: SizedBox.expand(),
            ),
          ),
        );

        final n1 = NotificationWidget(
          message: 'First item',
          channelName: 'test',
        );
        final n2 = NotificationWidget(
          message: 'Second item',
          channelName: 'test',
        );

        n1.show();
        await tester.pumpAndSettle();
        n2.show();
        await tester.pumpAndSettle();

        final finder2 = find.text('Second item');
        final finder1 = find.text('First item');

        final startPos = tester.getCenter(finder2);
        final targetPos = tester.getCenter(finder1);

        final gesture = await tester.startGesture(startPos);
        await tester.pump(const Duration(milliseconds: 100));

        await gesture.moveTo(targetPos);
        await tester.pump();

        expect(find.text('Second item'), findsWidgets);

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Relocate preserves effectiveCoordinator without null exception after '
      'relocation',
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
          message: 'Relocate item',
          channelName: 'test',
        ).show();
        await tester.pumpAndSettle();

        final notifFinder = find.text('Relocate item');
        final startPos = tester.getCenter(notifFinder);

        await tester.drag(notifFinder, Offset(-startPos.dx, -startPos.dy));
        await tester.pumpAndSettle();

        expect(find.text('Relocate item'), findsOneWidget);
        final activeQueues =
            FlutterNotificationQueue.coordinator.activeQueues.value;
        expect(activeQueues.containsKey(QueuePosition.topLeft), isTrue);

        final activeNotifs =
            FlutterNotificationQueue.coordinator.activeNotifications;
        expect(activeNotifs, isNotEmpty);
        expect(
          activeNotifs.first.effectiveCoordinator,
          equals(FlutterNotificationQueue.coordinator),
        );
      },
    );
  });
}
