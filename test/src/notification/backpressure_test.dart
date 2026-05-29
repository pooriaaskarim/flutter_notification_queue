import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Backpressure Strategy Integration Tests', () {
    setUp(() {
      // Configuration will be overridden in individual test cases if needed
    });

    tearDown(() {
      FlutterNotificationQueue.reset();
    });

    testWidgets(
      'unbounded pending queue by default (no capacity limit)',
      (final tester) async {
        FlutterNotificationQueue.configure(
          queues: {
            const TopCenterQueue(
              maxStackSize: 1,
              maxPendingSize: null, // default is null
            ),
          },
        );

        await tester.pumpWidget(
          const MaterialApp(
            builder: FlutterNotificationQueue.builder,
            home: Scaffold(
              body: SizedBox.expand(),
            ),
          ),
        );

        // Enqueue 5 items into maxStackSize: 1 queue
        final n1 = NotificationWidget(id: 'n1', message: 'Item 1');
        final n2 = NotificationWidget(id: 'n2', message: 'Item 2');
        final n3 = NotificationWidget(id: 'n3', message: 'Item 3');
        final n4 = NotificationWidget(id: 'n4', message: 'Item 4');
        final n5 = NotificationWidget(id: 'n5', message: 'Item 5');

        n1.show();
        n2.show();
        n3.show();
        n4.show();
        n5.show();

        await tester.pumpAndSettle();

        // 1 active, others pending
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsNothing);

        // Now dismiss Item 1 to let subsequent items flow
        await n1.dismiss();
        await tester.pumpAndSettle();

        expect(find.text('Item 2'), findsOneWidget);

        await n2.dismiss();
        await tester.pumpAndSettle();

        expect(find.text('Item 3'), findsOneWidget);
      },
    );

    testWidgets(
      'discardOldest strategy drops oldest pending and '
      'emits QueueOverflowed event',
      (final tester) async {
        FlutterNotificationQueue.configure(
          queues: {
            const TopCenterQueue(
              maxStackSize: 1,
              maxPendingSize: 2,
              overflowStrategy: QueueOverflowStrategy.discardOldest,
            ),
          },
        );

        await tester.pumpWidget(
          const MaterialApp(
            builder: FlutterNotificationQueue.builder,
            home: Scaffold(
              body: SizedBox.expand(),
            ),
          ),
        );

        final events = <FnqEvent>[];
        final subscription = FlutterNotificationQueue.events.listen(events.add);

        // Enqueue 4 items: n1 becomes active, n2 & n3 fill up the pending
        // queue of size 2.
        final n1 = NotificationWidget(id: 'n1', message: 'Active Item');
        final n2 = NotificationWidget(id: 'n2', message: 'Pending Item 2');
        final n3 = NotificationWidget(id: 'n3', message: 'Pending Item 3');
        final n4 = NotificationWidget(id: 'n4', message: 'Pending Item 4');

        n1.show();
        n2.show();
        n3.show();

        await tester.pumpAndSettle();

        // Pending queue is now full: [n2, n3]
        expect(find.text('Active Item'), findsOneWidget);

        // Enqueue n4: should overflow and drop n2 (oldest pending)
        n4.show();
        await tester.pumpAndSettle();

        // Verify the dropped event was received
        final overflowEvents = events.whereType<QueueOverflowed>().toList();
        expect(overflowEvents.length, 1);
        expect(overflowEvents.first.dropped.id, 'n2');

        // Dismiss n1: should promote n3, not n2
        await n1.dismiss();
        await tester.pumpAndSettle();

        expect(find.text('Pending Item 3'), findsOneWidget);
        expect(find.text('Pending Item 2'), findsNothing);

        // Dismiss n3: should promote n4
        await n3.dismiss();
        await tester.pumpAndSettle();

        expect(find.text('Pending Item 4'), findsOneWidget);

        await subscription.cancel();
      },
    );

    testWidgets(
      'discardNewest strategy rejects incoming item and '
      'emits QueueOverflowed event',
      (final tester) async {
        FlutterNotificationQueue.configure(
          queues: {
            const TopCenterQueue(
              maxStackSize: 1,
              maxPendingSize: 2,
              overflowStrategy: QueueOverflowStrategy.discardNewest,
            ),
          },
        );

        await tester.pumpWidget(
          const MaterialApp(
            builder: FlutterNotificationQueue.builder,
            home: Scaffold(
              body: SizedBox.expand(),
            ),
          ),
        );

        final events = <FnqEvent>[];
        final subscription = FlutterNotificationQueue.events.listen(events.add);

        // Enqueue 4 items: n1 becomes active, n2 & n3 fill up the pending
        // queue of size 2.
        final n1 = NotificationWidget(id: 'n1', message: 'Active Item');
        final n2 = NotificationWidget(id: 'n2', message: 'Pending Item 2');
        final n3 = NotificationWidget(id: 'n3', message: 'Pending Item 3');
        final n4 = NotificationWidget(id: 'n4', message: 'Pending Item 4');

        n1.show();
        n2.show();
        n3.show();

        await tester.pumpAndSettle();

        // Enqueue n4: should overflow and drop n4 itself (newest)
        n4.show();
        await tester.pumpAndSettle();

        // Verify the dropped event was received for n4
        final overflowEvents = events.whereType<QueueOverflowed>().toList();
        expect(overflowEvents.length, 1);
        expect(overflowEvents.first.dropped.id, 'n4');

        // Dismiss n1: should promote n2
        await n1.dismiss();
        await tester.pumpAndSettle();

        expect(find.text('Pending Item 2'), findsOneWidget);

        // Dismiss n2: should promote n3
        await n2.dismiss();
        await tester.pumpAndSettle();

        expect(find.text('Pending Item 3'), findsOneWidget);
        expect(find.text('Pending Item 4'), findsNothing);

        await subscription.cancel();
      },
    );
  });
}
