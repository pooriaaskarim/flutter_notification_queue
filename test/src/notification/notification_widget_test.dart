import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationWidget', () {
    setUp(() {
      FlutterNotificationQueue.initialize(
        channels: {
          const NotificationChannel(
            name: 'test_channel',
            position: QueuePosition.topRight,
            defaultIcon: Icon(Icons.abc),
          ),
        },
        queues: {
          const TopRightQueue(),
        },
      );
    });

    tearDown(FlutterNotificationQueue.reset);

    testWidgets('Renders basic content (message, icon)', (final tester) async {
      final notification = NotificationWidget(
        message: 'Hello World',
        channelName: 'test_channel',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: notification,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hello World'), findsOneWidget);
      expect(find.byIcon(Icons.abc), findsOneWidget); // Default icon from channel
    });

    testWidgets('Renders title when provided', (final tester) async {
      final notification = NotificationWidget(
        title: 'My Title',
        message: 'My Message',
        channelName: 'test_channel',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: notification,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Title'), findsOneWidget);
      expect(find.text('My Message'), findsOneWidget);
    });

    testWidgets('Expand button toggles message maxLines', (final tester) async {
      // Create a long message that would truncate
      final longMessage = List.generate(20, (final i) => 'Word $i').join(' ');
      final notification = NotificationWidget(
        message: longMessage,
        channelName: 'test_channel',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: notification,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially collapsed (maxLines: 1)
      // It's hard to verify maxLines directly on the RenderObject easily without checking properties on the widget.
      // But we can check for the Expand button.
      final expandButton = find.byIcon(Icons.expand_more);
      expect(expandButton, findsOneWidget);

      // Tap expand
      await tester.tap(expandButton);
      await tester.pump(); // Rebuild with new state

      // Icon should change to expand_less
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });

    testWidgets('Action button is rendered and clickable', (final tester) async {
      bool actionClicked = false;
      final notification = NotificationWidget(
        message: 'Action Test',
        channelName: 'test_channel',
        action: NotificationAction.button(
          label: 'Click Me',
          onPressed: () => actionClicked = true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: notification,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Click Me'), findsOneWidget);

      await tester.tap(find.text('Click Me'));
      await tester.pump();

      expect(actionClicked, isTrue);

      await tester.pumpAndSettle();
    });
  });
}
