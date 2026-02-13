import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_notification_queue/src/notification_queue/notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper to access state
QueueWidgetState getState(final WidgetTester tester) =>
    tester.state<QueueWidgetState>(find.byType(QueueWidget));

void main() {
  group('QueueWidgetState', () {
    setUp(() {
      // Initialize system
      FlutterNotificationQueue.initialize(
        queues: {
          const TopRightQueue(maxStackSize: 2), // Limit 2 for testing overflow
        },
        channels: {
          const NotificationChannel(
            name: 'default',
            description: 'Default channel',
          ),
        },
      );
    });

    testWidgets('enqueue adds to active list immediately if under limit',
        (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QueueWidget(
              queue: TopRightQueue(maxStackSize: 2),
            ),
          ),
        ),
      );

      final state = getState(tester);
      final notification = NotificationWidget(
        id: 'n1',
        message: 'Message 1',
      );

      state.enqueue(notification);
      // Pump to start animation and settle it
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Message 1'), findsOneWidget);
    });

    testWidgets('enqueue adds to pending if over limit', (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QueueWidget(
              queue: TopRightQueue(maxStackSize: 2),
            ),
          ),
        ),
      );

      final state = getState(tester);
      final n1 = NotificationWidget(id: 'n1', message: 'Message 1');
      final n2 = NotificationWidget(id: 'n2', message: 'Message 2');
      final n3 = NotificationWidget(id: 'n3', message: 'Message 3');

      state
        ..enqueue(n1)
        ..enqueue(n2);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Message 1'), findsOneWidget);
      expect(find.text('Message 2'), findsOneWidget);

      state.enqueue(n3);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Message 3'), findsNothing); // Should be pending
    });

    testWidgets('dismiss promotes pending item', (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QueueWidget(
              queue: TopRightQueue(maxStackSize: 2),
            ),
          ),
        ),
      );

      final state = getState(tester);
      final n1 = NotificationWidget(id: 'n1', message: 'Message 1');
      final n2 = NotificationWidget(id: 'n2', message: 'Message 2');
      final n3 = NotificationWidget(id: 'n3', message: 'Message 3');

      state
        ..enqueue(n1)
        ..enqueue(n2)
        ..enqueue(n3);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Message 3'), findsNothing);

      state.dismiss(n1);
      await tester.pumpAndSettle(); // Allow animations

      expect(find.text('Message 3'), findsOneWidget);
      expect(find.text('Message 1'), findsNothing);
    });

    testWidgets('update existing notification (active)', (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QueueWidget(
              queue: TopRightQueue(),
            ),
          ),
        ),
      );

      final state = getState(tester);
      final n1 = NotificationWidget(id: 'n1', message: 'Original');
      state.enqueue(n1);
      await tester.pump();
      await tester.pumpAndSettle(); // Settle entry animation
      expect(find.text('Original'), findsOneWidget);

      final n1Update = NotificationWidget(id: 'n1', message: 'Updated');
      state.enqueue(n1Update);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Updated'), findsOneWidget);
      expect(find.text('Original'), findsNothing);
    });
  });
}
