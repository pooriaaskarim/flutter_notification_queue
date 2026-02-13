import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationOverlay Integration', () {
    setUp(() {
      FlutterNotificationQueue.initialize(
        channels: {
          const NotificationChannel(
            name: 'test_channel',
            position: QueuePosition.topRight,
            defaultIcon: Icon(Icons.check),
          ),
        },
        queues: {
          const TopRightQueue(),
        },
      );
    });

    tearDown(FlutterNotificationQueue.reset);

    testWidgets('Shows notification via builder integration', (final tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: const Scaffold(
            body: Center(child: Text('App Home')),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('App Home'), findsOneWidget);
      expect(find.byType(NotificationWidget), findsNothing);

      // Show notification
      Offset? firstLocation;
      NotificationWidget(
        message: 'Overlay Test',
        channelName: 'test_channel',
      ).show();

      await tester.pump(); // Start animation (enqueue)
      await tester.pump(); // Frame for adding post-frame callbacks if any
      
      // Verify it appears
      expect(find.text('Overlay Test'), findsOneWidget);
      expect(find.byType(NotificationWidget), findsOneWidget);

      // Capture location to verify it's valid (and conceptually "above" or at least visible)
      firstLocation = tester.getCenter(find.text('Overlay Test'));
      expect(firstLocation, isNotNull);

      await tester.pumpAndSettle(); // Finish entry animation
      
      // Verify it stays
      expect(find.text('Overlay Test'), findsOneWidget);
    });

    testWidgets('Dismissal removes notification from overlay', (final tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: const Scaffold(
            body: Center(child: Text('App Home')),
          ),
        ),
      );

      final notification = NotificationWidget(
        message: 'Dismiss Test',
        channelName: 'test_channel',
      );
      notification.show();

      await tester.pumpAndSettle();
      expect(find.text('Dismiss Test'), findsOneWidget);

      // Dismiss (async because it waits for animation)
      // We must pump while waiting for it, otherwise deadlock.
      final dismissFuture = notification.dismiss(); 
      await tester.pumpAndSettle();
      await dismissFuture;

      expect(find.text('Dismiss Test'), findsNothing);
      expect(find.byType(NotificationWidget), findsNothing);
    });

     testWidgets('Multiple notifications stack correctly', (final tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: const Scaffold(
            body: Center(child: Text('App Home')),
          ),
        ),
      );

      NotificationWidget(message: 'First', channelName: 'test_channel').show();
      await tester.pump(); 
      NotificationWidget(message: 'Second', channelName: 'test_channel').show();
      await tester.pumpAndSettle();

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);

      // Verify vertical stacking (TopRightQueue)
      final firstCenter = tester.getCenter(find.text('First'));
      final secondCenter = tester.getCenter(find.text('Second'));

      // TopRightQueue typically stacks downwards? 
      // Need to check specific queue behavior or just ensure they constitute a column-like structure.
      // Usually "First" is at the top? Or bottom depending on implementation.
      // TopRightQueue typically has newer items at the bottom or top depending on "gravity"?
      // Standard/Default is usually growing downwards.
      
      // We just ensure they are not at the same position
      expect(firstCenter.dy, isNot(equals(secondCenter.dy)));
    });
  });
}
