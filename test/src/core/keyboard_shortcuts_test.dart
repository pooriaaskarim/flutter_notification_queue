import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Keyboard Shortcuts Tests', () {
    setUp(() {
      FlutterNotificationQueue.configure(
        channels: {
          const NotificationChannel(
            name: 'test_channel',
            position: QueuePosition.topRight,
            defaultDismissDuration: null,
          ),
        },
        queues: {
          const TopRightQueue(),
        },
      );
    });

    tearDown(FlutterNotificationQueue.reset);

    testWidgets('Esc key dismisses only the newest notification',
        (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(
            body: Center(child: Text('App Home')),
          ),
        ),
      );

      // Create and show two notifications
      NotificationWidget(
        id: 'n1',
        message: 'First Notification',
        channelName: 'test_channel',
      ).show();

      // Pump to let the first register
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      NotificationWidget(
        id: 'n2',
        message: 'Second Notification',
        channelName: 'test_channel',
      ).show();

      await tester.pumpAndSettle();

      expect(find.text('First Notification'), findsOneWidget);
      expect(find.text('Second Notification'), findsOneWidget);

      // Send Escape key event
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // n2 (the newest notification) should be dismissed, n1 remains
      expect(find.text('Second Notification'), findsNothing);
      expect(find.text('First Notification'), findsOneWidget);

      // Send Escape key event again
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // n1 should be dismissed as well
      expect(find.text('First Notification'), findsNothing);
    });

    testWidgets('Shift + Esc key dismisses all active notifications',
        (final tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          builder: FlutterNotificationQueue.builder,
          home: Scaffold(
            body: Center(child: Text('App Home')),
          ),
        ),
      );

      NotificationWidget(
        id: 'n1',
        message: 'First Notification',
        channelName: 'test_channel',
      ).show();

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      NotificationWidget(
        id: 'n2',
        message: 'Second Notification',
        channelName: 'test_channel',
      ).show();

      await tester.pumpAndSettle();

      expect(find.text('First Notification'), findsOneWidget);
      expect(find.text('Second Notification'), findsOneWidget);

      // Simulate Shift + Escape key press
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      // Both notifications should be dismissed
      expect(find.text('First Notification'), findsNothing);
      expect(find.text('Second Notification'), findsNothing);
    });
  });
}
